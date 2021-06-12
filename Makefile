.PHONY: test nvim lint
nvim:
	nvim --noplugin -u scripts/minimal_init.lua $(ARGS)

test:
	nvim --headless --noplugin -u scripts/minimal_init.lua -c "PlenaryBustedDirectory lua/tests/ { minimal_init = './scripts/minimal_init.lua' }"

lint:
	pre-commit run --all-files
