#!/usr/bin/env zsh

echo "Cleaning zsh/zinit cache..."

# Remove compiled cache files
if find ~/.local/share/zinit -name "*.zwc" -type f -delete 2>/dev/null; then
  echo "✓ Removed compiled .zwc files"
fi

# Remove zsh completion cache
if rm ~/.zcompdump* 2>/dev/null; then
  echo "✓ Removed .zcompdump files"
fi

# Remove p10k cache
if rm ~/.cache/p10k-* 2>/dev/null; then
  echo "✓ Removed p10k cache"
fi

echo ""
echo "Cache cleaned! Run 'exec zsh' or restart your terminal to rebuild."
