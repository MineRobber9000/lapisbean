ASSETS := $(filter-out ./README.md ./.git% ./%Makefile ./%.com, $(shell find . -type f))

ZIP := $(shell which zip)
ZIP := $(if $(ZIP),$(ZIP),./zip.com)

lapisbean.com: $(ASSETS) redbean.com $(ZIP)
	cp redbean.com $@
	$(ZIP) $@ -d favicon.ico
	$(ZIP) $@ $(filter-out $(ZIP),$(filter-out %.com, $^))

redbean.com:
	wget -O redbean.com https://redbean.dev/redbean-latest.com
	chmod +x redbean.com

zip.com:
	wget -O zip.com https://cosmo.zip/pub/cosmos/bin/zip
	chmod +x zip.com

.PHONY: clean deep-clean test
clean:
	rm -f lapisbean.com
deep-clean:
	rm -f lapisbean.com redbean.com zip.com
test: redbean.com
	./redbean.com -D .
