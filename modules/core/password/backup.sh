#!/usr/bin/env bash
# Credits to https://github.com/michael-batz/1password-backup

print_usage()
{
    echo "1Password Cloud Backup"
    echo "usage: $0 -f <output file> [-a|--account <shorthand>] [-v|--vault-item <uuid>]"
    echo ""
    echo "Options:"
    echo "  -f    Path to the encrypted output file"
    echo "  -a    1Password account shorthand (optional)"
    echo "  -p    UUID of the vault item containing the encryption password (optional)"
    exit 0
}

notify-send "Starting 1Password backup..."
sleep 2

# define variables
tool_op="op"
tool_jq="jq"
var_account=""
var_vault_uuid=""

# parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f) var_outputfile="$2"; shift ;;
        -a|--account) var_account="$2"; shift ;;
        -p|--password) var_vault_uuid="$2"; shift ;;
        *) print_usage ;;
    esac
    shift
done

# check arguments
if [ -z "${var_outputfile}" ]; then print_usage; fi

# signin to 1Password
echo "1Password Cloud Backup"
echo "- signin to 1Password..."

if [ -n "${var_account}" ]; then
    eval $(${tool_op} signin --account "${var_account}")
else
    eval $(${tool_op} signin)
fi

# Fetch the encryption password if a UUID was provided
encryption_pass=""
if [ -n "${var_vault_uuid}" ]; then
    echo "- fetching encryption password from vault item ${var_vault_uuid}..."
    # Extracts the 'password' field from the specified item
    encryption_pass=$(${tool_op} item get "${var_vault_uuid}" --reveal --fields password)

    if [ -z "${encryption_pass}" ]; then
        echo "Error: Could not retrieve password from item ${var_vault_uuid}."
        exit 1
    fi
fi

# get a list of all items
echo "- get all items from 1Password..."
output=$(${tool_op} item list --format json --include-archive | op item get - --reveal --format json)

# encrypt items and write to output file
echo "- store items in encrypted output file ${var_outputfile}..."

if [ -n "${encryption_pass}" ]; then
    # Use the password from the vault (pbkdf2 is recommended for modern openssl)
    echo "$output" | openssl enc -e -aes256 -pbkdf2 -pass "pass:${encryption_pass}" -out "${var_outputfile}"
else
    # Fallback to manual password prompt if no UUID was provided
    echo "$output" | openssl enc -e -aes256 -pbkdf2 -out "${var_outputfile}"
fi

# signout from 1Password
echo "- signout from 1Password"
${tool_op} signout
