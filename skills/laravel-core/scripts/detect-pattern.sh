#!/usr/bin/env bash
# Détection du pattern architectural d'un projet Laravel
set -euo pipefail

PROJECT_DIR="${1:-.}"

echo "🔍 Analyse du projet Laravel dans : $PROJECT_DIR"
echo ""

# Vérifier que c'est un projet Laravel
if [ ! -f "$PROJECT_DIR/composer.json" ]; then
    echo "❌ Pas de composer.json trouvé. Ce n'est pas un projet PHP."
    exit 1
fi

if ! grep -q "laravel/framework" "$PROJECT_DIR/composer.json" 2>/dev/null; then
    echo "❌ laravel/framework non trouvé dans composer.json."
    exit 1
fi

echo "✅ Projet Laravel détecté"
echo ""

# Détecter le pattern
PATTERNS=()

# Inertia.js
if grep -q "inertiajs/inertia-laravel" "$PROJECT_DIR/composer.json" 2>/dev/null; then
    PATTERNS+=("inertia")
    echo "📦 Inertia.js détecté"
    # Détecter le framework frontend
    if grep -q "vue" "$PROJECT_DIR/package.json" 2>/dev/null || [ -f "$PROJECT_DIR/resources/js/app.ts" ] && grep -q "vue" "$PROJECT_DIR/resources/js/app.ts" 2>/dev/null; then
        echo "   → Vue.js"
    elif grep -q "react" "$PROJECT_DIR/package.json" 2>/dev/null || [ -f "$PROJECT_DIR/resources/js/app.tsx" ]; then
        echo "   → React"
    fi
fi

# Livewire
if grep -q "livewire/livewire" "$PROJECT_DIR/composer.json" 2>/dev/null; then
    PATTERNS+=("livewire")
    echo "📦 Livewire détecté"
fi

# API
if grep -q "Route::apiResource\|Route::prefix.*api\|->prefix('api')" "$PROJECT_DIR/routes/"*.php 2>/dev/null; then
    PATTERNS+=("api")
    echo "📦 API REST détectée"
fi

# AI
if grep -q "laravel/ai\|openai-php/client\|anthropic-php" "$PROJECT_DIR/composer.json" 2>/dev/null; then
    PATTERNS+=("ai")
    echo "📦 AI/LLM intégré"
fi

# MCP
if grep -q "laravel/boost\|mcp" "$PROJECT_DIR/composer.json" 2>/dev/null || [ -f "$PROJECT_DIR/.mcp.json" ]; then
    PATTERNS+=("mcp")
    echo "📦 MCP détecté"
fi

# Queues / Horizon
if grep -q "laravel/horizon" "$PROJECT_DIR/composer.json" 2>/dev/null; then
    PATTERNS+=("queue")
    echo "📦 Horizon (queues) détecté"
elif grep -q "'QUEUE_CONNECTION'" "$PROJECT_DIR/.env" 2>/dev/null && ! grep -q "'QUEUE_CONNECTION'=sync" "$PROJECT_DIR/.env" 2>/dev/null; then
    PATTERNS+=("queue")
    echo "📦 Queues configurées (non-sync)"
fi

# WebSocket / Reverb
if grep -q "laravel/reverb" "$PROJECT_DIR/composer.json" 2>/dev/null; then
    PATTERNS+=("websocket")
    echo "📦 Reverb (WebSocket) détecté"
elif grep -q "BROADCAST_DRIVER=reverb" "$PROJECT_DIR/.env" 2>/dev/null; then
    PATTERNS+=("websocket")
    echo "📦 Broadcasting Reverb configuré"
fi

# Admin / Filament
if grep -q "filament/filament" "$PROJECT_DIR/composer.json" 2>/dev/null; then
    PATTERNS+=("admin")
    echo "📦 Filament (admin) détecté"
fi

# Multi-tenancy
if grep -q "stancl/tenancy\|archtechx/tenancy" "$PROJECT_DIR/composer.json" 2>/dev/null; then
    PATTERNS+=("multi-tenancy")
    echo "📦 Multi-tenancy détecté"
fi

# Microservices
if [ -d "$PROJECT_DIR/services" ] || [ -d "$PROJECT_DIR/packages" ] || grep -q "event-sourcing\|spatie/laravel-event-sourcing" "$PROJECT_DIR/composer.json" 2>/dev/null; then
    PATTERNS+=("microservice")
    echo "📦 Microservices / Event Sourcing détecté"
fi

# Déterminer le type principal
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${#PATTERNS[@]} -eq 0 ]; then
    echo "📋 Type : Monolithe Blade (pattern par défaut)"
    echo "📋 Skills : laravel-core + testing + security + performance + deploy"
else
    echo "📋 Patterns détectés : ${PATTERNS[*]}"
    echo ""
    echo "📋 Skills recommandés :"
    echo "   laravel-core (obligatoire)"
    for p in "${PATTERNS[@]}"; do
        case "$p" in
            inertia)       echo "   laravel-inertia" ;;
            livewire)      echo "   laravel-livewire" ;;
            api)           echo "   laravel-api" ;;
            ai)            echo "   laravel-ai" ;;
            mcp)           echo "   laravel-mcp" ;;
            queue)         echo "   laravel-queue" ;;
            websocket)     echo "   laravel-websocket" ;;
            admin)         echo "   laravel-admin" ;;
            multi-tenancy) echo "   laravel-multi-tenancy" ;;
            microservice)  echo "   laravel-microservice" ;;
        esac
    done
    echo "   laravel-testing (recommandé)"
    echo "   laravel-security (recommandé)"
    echo "   laravel-performance (recommandé)"
    echo "   laravel-deploy (recommandé)"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
