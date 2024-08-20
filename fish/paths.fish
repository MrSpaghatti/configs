# Add ~/zig to PATH
if test -d ~/zig
	if not contains -- ~/zig $PATH
		set -p PATH ~/zig
	end
end

# Add ~/.local/bin to PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Add depot_tools to PATH
if test -d ~/Applications/depot_tools
    if not contains -- ~/Applications/depot_tools $PATH
        set -p PATH ~/Applications/depot_tools
    end
end

# Add ~/lite to PATH
if test -d ~/lite
	if not contains -- ~/lite $PATH
		set -p PATH ~/lite
	end
end
