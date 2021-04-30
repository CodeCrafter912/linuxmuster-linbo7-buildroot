TOPDIR := $(shell pwd)

PROJECT_DEFCONFIG = $(shell grep BR2_DEFCONFIG= buildroot/.config | sed -e 's/.*"\(.*\)"/\1/')

MAKE_BR = make -C buildroot BR2_EXTERNAL=$(TOPDIR) BR2_DL_DIR=$(TOPDIR)/dl

# global
#.buildStep-buildrootDownloaded:
#	@echo "Downloading Buildroot..."
#	git submodule update --recursive || exit 1
#	@touch .buildStep-buildrootDownloaded

# Apply our patches that either haven't been submitted or merged upstream yet
#.buildStep-buildrootPatched: .buildStep-buildrootDownloaded
#	buildroot/support/scripts/apply-patches.sh buildroot patches || exit 1
#	touch .buildStep-buildrootPatched

#reset-buildroot: .buildStep-buildrootDownloaded
#	# Reset buildroot to a pristine condition so that the
#	# patches can be applied again.
#	cd buildroot && git clean -fdx && git reset --hard
#	rm -f .buildStep-buildrootPatched

#update-patches: reset-buildroot .buildStep-buildrootPatched
# end - global

# board specific
%_defconfig: configs/%_defconfig
	$(call calculate-target-vars,$@)
	$(MAKE_TARGET) $(TARGET)_defconfig

	@echo
	@echo
	@echo "The target $(TARGET) is now initialized!"
	@echo "You may now use the following commands:"
	@echo "  make $(TARGET)_source 		Download all sources so an offline build is possible"
	@echo "  make $(TARGET)_all			Build everything"
	@echo "  make $(TARGET)_clean		Clean everything"
	@echo "  make $(TARGET)_menuconfig	Open the menuconfig"
	@echo "  make $(TARGET)_save		Save to current configuration to the respective defconfig"

%_all: %_isInited
	$(MAKE_TARGET) -j8
	@echo
	@echo "Project has been built successfully."
	@echo "Images are in buildroot/output/images."

%_source: %_isInited
	$(MAKE_TARGET) source
	@echo
	@echo "All sources downloaded"

%_menuconfig: %_isInited
	$(MAKE_TARGET) menuconfig
	@echo
	@echo "!!! Important !!!"
	@echo "$(TARGET_DEFCONFIG) has NOT been updated."
	@echo "Changes will be lost if you run 'make distclean'."
	@echo "Please run"
	@echo
	@echo "make $(TARGET)_save"
	@echo
	@echo "to update the defconfig."

%_linux-menuconfig: %_isInited
	$(MAKE_TARGET) linux-menuconfig
	$(MAKE_TARGET) linux-savedefconfig
	@echo
	@echo "----------------------------------------"
	@echo Going to update your boards/$(TARGET)/linux.config. If you do not have one,
	@echo you will get an error shortly. You will then have to make one and update
	@echo your buildroot configuration to use it.
	@echo To do so, place your linux config into boards/$(TARGET)/linux.config
	@echo and add the line 
	@echo BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE=\"$$\(BR2_EXTERNAL\)/board/$(TARGET)/linux.config\"
	@echo to your defconfig. Dont forget to run make $(TARGET)_defconfig afterwards.
	@echo "----------------------------------------"
	@echo
	$(MAKE_TARGET) linux-update-defconfig

%_busybox-menuconfig: %_isInited
	$(MAKE_TARGET) busybox-menuconfig
	@echo
	@echo "----------------------------------------"
	@echo Going to update your boards/$(TARGET)/busybox.config. If you do not have one,
	@echo you will get an error shortly. You will then have to make one and update
	@echo your buildroot configuration to use it.
	@echo To do so, place your busybox config into boards/$(TARGET)/busybox.config and add the line 
	@echo BR2_PACKAGE_BUSYBOX_CONFIG=\"$$\(BR2_EXTERNAL\)/board/$(TARGET)/busybox.config\"
	@echo to your defconfig. Dont forget to run make $(TARGET)_defconfig afterwards.
	@echo "----------------------------------------"
	@echo
	$(MAKE_TARGET) busybox-update-config

%_clean: %_isInited
	$(MAKE_TARGET) clean

%_save: %_savedefconfig
	@echo "Done."

%_savedefconfig: %_isInited
	$(MAKE_TARGET) savedefconfig
# end - board specific

# Helper stuff
define calculate-target-vars
	$(eval TARGET := $(word 1,$(subst _, ,$(1))))
	$(eval TARGET_DEFCONGIG := $(TOPDIR)/configs/$(TARGET)_defconfig)
	$(eval TARGET_OUTPUTS := $(TOPDIR)/outputs/$(TARGET))
	$(eval TARGET_IMAGES := $(TARGET_OUTPUTS)/images)
	$(eval MAKE_TARGET := $(MAKE_BR) O=$(TARGET_OUTPUTS))
endef

%_isInited: outputs/%/.config
	@echo "Target is inited!"
	$(call calculate-target-vars,$@)
	@echo "----------------------------------------"
	@echo "TARGET:			$(TARGET)"
	@echo "TARGET_DEFCONGIG: 	$(TARGET_DEFCONGIG)"
	@echo "TARGET_OUTPUTS:		$(TARGET_OUTPUTS)"
	@echo "TARGET_IMAGES:		$(TARGET_IMAGES)"
	@echo "MAKE_TARGET:		$(MAKE_TARGET)"
	@echo "----------------------------------------"

outputs/%/.config:
	$(eval TARGET := $(subst outputs/,,$@))
	$(eval TARGET := $(subst /.config,,$(TARGET)))
	@echo "The target \"$(TARGET)\" is not initialized yet!"
	@echo "Please run"
	@echo
	@echo "make $(TARGET)_defconfig"
	@echo
	@echo "to initialize it!"
	@false

configs/%_defconfig:
	@echo "ERROR: This defconfig does not exist!"
	@false
# end - Helper stuff

help:
	@echo 'Project Build Help'
	@echo '------------------'
	@echo
	@echo 'Actions:'
	@echo "  <target>_all		Build everything"
	@echo "  <target>_clean	Clean everything"
	@echo "  <target>_menuconfig	Open the menuconfig"
	@echo "  <target>_save		Save to current configuration to the respective defconfig"
	@echo "  Where <target> is one of the available targets."
	@echo
	@echo "Available targets:"
	@$(foreach b, $(sort $(notdir $(wildcard configs/*_defconfig))), \
	  printf "  * %s\\n" $(b:_defconfig=);)
