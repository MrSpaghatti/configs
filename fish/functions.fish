function my_paths --description "list paths in order"
	echo "#  "
	printf '%s\%n' (String split \n $PATH)
end

function start --description "systemctl start *wtv processes u type*"
	for arg in $argv
		sudo systemctl start $arg
	end
end
