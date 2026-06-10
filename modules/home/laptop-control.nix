{ config, pkgs, ... }:
let
  noctaliaPackage = config.programs.noctalia-shell.package;
  laptopControlServer = pkgs.writeText "laptop-control-server.js" ''
    #!${pkgs.nodejs}/bin/node
    const fs = require("node:fs");
    const http = require("node:http");
    const os = require("node:os");
    const path = require("node:path");
    const { spawn } = require("node:child_process");

    const host = process.env.LAPTOP_CONTROL_HOST || "0.0.0.0";
    const port = Number(process.env.LAPTOP_CONTROL_PORT || "8765");
    const stateDir = path.join(
      process.env.XDG_STATE_HOME || path.join(os.homedir(), ".local/state"),
      "laptop-control",
    );
    const stateFile = path.join(stateDir, "state.json");
    const noctaliaShell = "${noctaliaPackage}/bin/noctalia-shell";
    const systemctl = "${pkgs.systemd}/bin/systemctl";

    function escapeHtml(value) {
      return String(value)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#39;");
    }

    function runCommand(command, args) {
      return new Promise((resolve, reject) => {
        const child = spawn(command, args, { stdio: ["ignore", "pipe", "pipe"] });
        let stdout = "";
        let stderr = "";

        child.stdout.on("data", (chunk) => {
          stdout += chunk;
        });
        child.stderr.on("data", (chunk) => {
          stderr += chunk;
        });
        child.on("error", reject);
        child.on("close", (code) => {
          if (code === 0) {
            resolve(stdout);
          } else {
            reject(new Error((stderr || stdout || `noctalia exited with ''${code}`).trim()));
          }
        });
      });
    }

    function runNoctaliaIpc(target, method) {
      return runCommand(noctaliaShell, ["ipc", "call", target, method]);
    }

    function loadState() {
      try {
        return JSON.parse(fs.readFileSync(stateFile, "utf8"));
      } catch {
        return { keepAwake: false };
      }
    }

    function saveState(state) {
      fs.mkdirSync(stateDir, { recursive: true });
      fs.writeFileSync(stateFile, JSON.stringify(state));
    }

    function page(message = "") {
      const state = loadState();
      const keepAwake = Boolean(state.keepAwake);
      const status = keepAwake ? "On" : "Off";
      const checked = keepAwake ? "checked" : "";
      const messageHtml = message ? `<p class="message">''${escapeHtml(message)}</p>` : "";

      return `<!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Laptop Control</title>
      <style>
        :root {
          color-scheme: dark;
          font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          background: #101418;
          color: #f4f7f8;
        }
        body {
          margin: 0;
          min-height: 100vh;
          display: grid;
          place-items: center;
          padding: 20px;
          box-sizing: border-box;
        }
        main {
          width: min(100%, 420px);
          display: grid;
          gap: 14px;
        }
        h1 {
          margin: 0 0 6px;
          font-size: 28px;
          font-weight: 720;
        }
        form {
          margin: 0;
        }
        button, .toggle {
          width: 100%;
          min-height: 58px;
          border: 1px solid #34424c;
          border-radius: 8px;
          background: #1b2329;
          color: inherit;
          font: inherit;
          font-size: 18px;
          font-weight: 650;
        }
        button:active, .toggle:active {
          transform: translateY(1px);
        }
        .danger {
          border-color: #724047;
          background: #32191d;
        }
        .toggle {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 18px;
          box-sizing: border-box;
        }
        .switch {
          width: 56px;
          height: 32px;
          border-radius: 999px;
          background: #3a454d;
          position: relative;
          flex: 0 0 auto;
        }
        .switch::after {
          content: "";
          position: absolute;
          width: 26px;
          height: 26px;
          top: 3px;
          left: 3px;
          border-radius: 50%;
          background: #fff;
          transition: transform 120ms ease;
        }
        input {
          position: absolute;
          opacity: 0;
          pointer-events: none;
        }
        input:checked + .switch {
          background: #2f8f61;
        }
        input:checked + .switch::after {
          transform: translateX(24px);
        }
        .message {
          margin: 0;
          color: #9fb2bd;
          min-height: 22px;
        }
      </style>
    </head>
    <body>
      <main>
        <h1>Laptop Control</h1>
        ''${messageHtml}
        <form method="post" action="/keep-awake">
          <label class="toggle">
            <span>Keep awake: ''${status}</span>
            <input type="checkbox" name="enabled" value="1" ''${checked} onchange="this.form.submit()">
            <span class="switch" aria-hidden="true"></span>
          </label>
        </form>
        <form method="post" action="/suspend">
          <button type="submit">Suspend</button>
        </form>
        <form method="post" action="/shutdown">
          <button class="danger" type="submit">Shutdown</button>
        </form>
      </main>
    </body>
    </html>`;
    }

    function sendHtml(response, body, status = 200) {
      response.writeHead(status, {
        "Content-Type": "text/html; charset=utf-8",
        "Content-Length": Buffer.byteLength(body),
      });
      response.end(body);
    }

    function redirect(response, message) {
      const body = page(message);
      response.writeHead(303, {
        Location: "/",
        "Content-Type": "text/html; charset=utf-8",
        "Content-Length": Buffer.byteLength(body),
      });
      response.end(body);
    }

    async function readBody(request) {
      const chunks = [];
      for await (const chunk of request) {
        chunks.push(chunk);
      }
      return Buffer.concat(chunks).toString("utf8");
    }

    const server = http.createServer(async (request, response) => {
      console.log(`''${request.socket.remoteAddress} ''${request.method} ''${request.url}`);

      if (request.method === "GET" && request.url === "/") {
        sendHtml(response, page());
        return;
      }

      if (request.method !== "POST") {
        sendHtml(response, page("Not found"), 404);
        return;
      }

      try {
        const body = await readBody(request);
        const form = new URLSearchParams(body);

        if (request.url === "/keep-awake") {
          const enabled = form.get("enabled") === "1";
          await runNoctaliaIpc("idleInhibitor", enabled ? "enable" : "disable");
          saveState({ keepAwake: enabled });
          redirect(response, enabled ? "Keep awake enabled" : "Keep awake disabled");
        } else if (request.url === "/suspend") {
          redirect(response, "Suspending");
          await runCommand(systemctl, ["suspend"]);
        } else if (request.url === "/shutdown") {
          redirect(response, "Shutting down");
          await runCommand(systemctl, ["poweroff"]);
        } else {
          sendHtml(response, page("Not found"), 404);
        }
      } catch (error) {
        sendHtml(response, page(`Command failed: ''${error.message}`), 500);
      }
    });

    server.listen(port, host, () => {
      console.log(`Serving laptop control on http://''${host}:''${port}`);
    });
  '';
in
{
  systemd.user.services.laptop-control = {
    Unit = {
      Description = "LAN laptop control web server";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.nodejs}/bin/node ${laptopControlServer}";
      Restart = "on-failure";
      Environment = [
        "LAPTOP_CONTROL_HOST=0.0.0.0"
        "LAPTOP_CONTROL_PORT=8765"
      ];
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
