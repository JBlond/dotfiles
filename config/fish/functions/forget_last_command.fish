function forget_last_command
	set last_typed_command (history --max 1)
	history delete --exact --case-sensitive "$last_typed_command"
	history save
end
