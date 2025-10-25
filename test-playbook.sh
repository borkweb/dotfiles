#!/usr/bin/env bash

set -e

echo "=== Ansible Dotfiles Test Suite ==="
echo

echo "1. Syntax check..."
ansible-playbook playbook.yml --syntax-check
echo "✓ Syntax OK"
echo

echo "2. Dry run (check mode)..."
ansible-playbook playbook.yml --check --diff | tee /tmp/ansible-check.log
echo "✓ Dry run complete"
echo

echo "3. Verify role structure..."
for role in common shell tmux neovim ideavim bin-utils wordpress; do
  if [ -d "roles/$role/tasks" ]; then
    echo "✓ Role $role exists"
  else
    echo "✗ Role $role missing"
    exit 1
  fi
done
echo

echo "4. Verify group_vars..."
for varfile in all darwin wsl; do
  if [ -f "group_vars/${varfile}.yml" ]; then
    echo "✓ group_vars/${varfile}.yml exists"
  else
    echo "✗ group_vars/${varfile}.yml missing"
    exit 1
  fi
done
echo

echo "=== All tests passed ==="
