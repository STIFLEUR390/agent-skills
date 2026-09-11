#!/usr/bin/env bash
# Vérification des outils optionnels pour project-definer

echo "=== Vérification des outils ==="
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

found=0
missing=0

# 1. find-docs (skill)
echo -n "find-docs : "
if [ -d "$HOME/.claude/skills/find-docs" ] || \
   [ -d "$HOME/.config/opencode/skills/find-docs" ] || \
   [ -d ".agents/skills/find-docs" ] || \
   [ -d "$HOME/.agents/skills/find-docs" ] || \
   [ -d "$HOME/.pi/agent/skills/find-docs" ]; then
    echo -e "${GREEN}✅ disponible${NC}"
    found=$((found + 1))
else
    echo -e "${RED}❌ non disponible${NC}"
    missing=$((missing + 1))
fi

# 2. agent-browser (CLI)
echo -n "agent-browser : "
if command -v agent-browser &>/dev/null; then
    version=$(agent-browser --version 2>/dev/null || echo "version inconnue")
    echo -e "${GREEN}✅ disponible ($version)${NC}"
    found=$((found + 1))
elif command -v npx &>/dev/null; then
    echo -e "${YELLOW}⚠️  installable via npx${NC}"
    found=$((found + 1))
else
    echo -e "${RED}❌ non disponible${NC}"
    missing=$((missing + 1))
fi

# 3. kaneo (MCP)
echo -n "mcp-kaneo : "
if command -v claude &>/dev/null && claude mcp list 2>/dev/null | grep -q kaneo; then
    echo -e "${GREEN}✅ configuré (Claude Code)${NC}"
    found=$((found + 1))
elif command -v npx &>/dev/null; then
    echo -e "${YELLOW}⚠️  installable via npx${NC}"
    found=$((found + 1))
else
    echo -e "${RED}❌ non disponible${NC}"
    missing=$((missing + 1))
fi

# 4. pi (pour pi-specific skills)
echo -n "pi-agent : "
if command -v pi &>/dev/null; then
    echo -e "${GREEN}✅ disponible${NC}"
    found=$((found + 1))
elif [ -d "$HOME/.pi/agent" ]; then
    echo -e "${GREEN}✅ installé (pas en PATH)${NC}"
    found=$((found + 1))
else
    echo -e "${YELLOW}⚠️  non détecté (ok si pas besoin)${NC}"
fi

# 5. Git
echo -n "git : "
if command -v git &>/dev/null; then
    version=$(git --version | cut -d' ' -f3)
    echo -e "${GREEN}✅ disponible (v$version)${NC}"
    found=$((found + 1))
else
    echo -e "${RED}❌ non disponible${NC}"
    missing=$((missing + 1))
fi

# 6. Node.js / npm (utile pour many tools)
echo -n "node : "
if command -v node &>/dev/null; then
    version=$(node --version)
    echo -e "${GREEN}✅ disponible ($version)${NC}"
    found=$((found + 1))
else
    echo -e "${YELLOW}⚠️  non disponible (ok si pas besoin)${NC}"
fi

echo ""
echo "=== Résumé ==="
echo -e "Outils trouvés : ${GREEN}$found${NC}"
echo -e "Outils manquants : ${RED}$missing${NC}"
echo ""

if [ $missing -gt 0 ]; then
    echo -e "${YELLOW}Note : les outils manquants ne bloquent pas le skill.${NC}"
    echo "Continuez sans eux, ils seront mentionnés dans les documents générés."
fi

echo "=== Fin de vérification ==="
