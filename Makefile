.PHONY: check verify

check: verify

verify:
	scripts/check-baseline.sh
