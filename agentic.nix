{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "agentic-ai-bootcamp-env - VJC AMO";

  # System packages provided by Nix
  buildInputs = with pkgs; [
    python312Packages.python
    uv
    sqlite
  ];

  # Setup hook that runs when you enter nix-shell
  shellHook = ''
    echo "===================================================="
    echo "🌌 Welcome to the Agentic AI Bootcamp Nix Environment - VJC AMO 🌌"
    echo "===================================================="
    echo "Using Python: $(python --version)"
    echo "Using uv:     $(uv --version)"
    echo "Using SQLite: $(sqlite3 --version)"
    echo "----------------------------------------------------"
    
    # Create virtual environment if it doesn't exist
    if [ ! -d ".venv" ]; then
      echo "🔧 Creating new virtual environment (.venv) using uv..."
      uv venv .venv
    fi
    
    # Activate virtual environment
    source .venv/bin/activate
    
    # Install dependencies using uv
    echo "📦 Installing/syncing Python packages from requirements.txt..."
    uv pip install -r requirements.txt
    
    echo "🚀 Environment is ready! Run your Jupyter Lab or Phoenix server:"
    echo "   - phoenix serve"
    echo "   - jupyter lab"
    echo "===================================================="
  '';
}
