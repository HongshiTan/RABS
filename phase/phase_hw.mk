############################## Setting up Kernel Variables ##############################
# Kernel compiler global settings
VPP_FLAGS += -t $(TARGET) --platform $(DEVICE) --save-temps --verbose
ifneq ($(TARGET), hw)
	VPP_FLAGS += -g
endif

VPP_FLAGS += -I ./src/ --vivado.param general.maxThreads=32 --vivado.synth.jobs 32
VPP_FLAGS += --remote_ip_cache  ./.rabs_ipcache

# Kernel linker flags
ifdef __ADVANCED_HLS__
	# adhoc support for fixed clock
	# VPP_LDFLAGS += --clock.defaultFreqHz $(FREQ)
else
	VPP_LDFLAGS += --kernel_frequency $(FREQ)
endif

VPP_LDFLAGS += --vivado.param general.maxThreads=32  --vivado.impl.jobs 32 --config ${DEFAULT_CFG}



.PHONY: xo
xo: $(BINARY_CONTAINER_OBJS)
	@${ECHO} "build all xo:" $(BINARY_CONTAINER_OBJS)

.PHONY: aie_obj
aie_obj: $(AIE_CONTAINER_OBJS)
	@${ECHO} "build all aie object:" $(AIE_CONTAINER_OBJS)

.PHONY: aie_xclbin
aie_xclbin: $(BUILD_DIR)/aie_kernel.xclbin
	@${ECHO} "build all aie object:" $(AIE_CONTAINER_OBJS)

$(BUILD_DIR)/aie_kernel.xclbin : $(AIE_CONTAINER_OBJS)
	$(VPP) -s -p -t $(TARGET) -f $(DEVICE) --package.out_dir ./	\
	       --package.defer_aie_run --config mk/misc/aie_xrt.ini -o $@ $<

.PHONY: aie_xsa
aie_xsa: $(BUILD_DIR)/kernel.xsa


aie_clean: ${AIE_CONTAINER_OBJS}
	@rm  -rf $(BUILD_DIR)/aie_kernel.xclbin
	@rm  -rf $(AIE_CONTAINER_OBJS)
	@${ECHO} $(TEMP_DIR)
	@${ECHO} $(subst $(TEMP_DIR),., ./$(dir $<))
	@rm  -rf $(subst $(TEMP_DIR),., ./$(dir $<))/.Xil
	@rm  -rf $(subst $(TEMP_DIR),., ./$(dir $<))/Work
	@rm  -rf $(subst $(TEMP_DIR),., ./$(dir $<))/*.log
	@rm  -rf $(subst $(TEMP_DIR),., ./$(dir $<))/libadf.a

.PHONY: aie_ps
aie_ps: $(TEMP_DIR)/$(UPPER_DIR)/$(APP_DIR)/ps.app


.PHONY: aie_all
aie_all: 	aie_xclbin aie_ps


$(BUILD_DIR)/kernel.xsa: $(BINARY_CONTAINER_OBJS) $(AIE_CONTAINER_OBJS)
	$(VPP) $(VPP_FLAGS) -l $(VPP_LDFLAGS) --temp_dir $(TEMP_DIR)  -o'$(BUILD_DIR)/kernel.xsa' $(BINARY_CONTAINER_OBJS) $(AIE_CONTAINER_OBJS)



############################## Setting Rules for Binary Containers (Building Kernels) ##############################
$(BUILD_DIR)/kernel.xclbin:  $(BINARY_CONTAINER_OBJS) $(AIE_CONTAINER_OBJS)
	@${ECHO} $(BINARY_CONTAINER_OBJS)
ifeq ($(__AIE_SET__), true)
	$(VPP) $(VPP_FLAGS) -l $(VPP_LDFLAGS) --temp_dir $(TEMP_DIR)  -o'$(BUILD_DIR)/kernel.xsa' $(BINARY_CONTAINER_OBJS) $(AIE_CONTAINER_OBJS)
	$(VPP) -p $(BUILD_DIR)/kernel.xsa $(AIE_CONTAINER_OBJS) --temp_dir $(TEMP_DIR)  -t $(TARGET) --platform $(DEVICE) -o $(BUILD_DIR)/kernel.xclbin  --package.out_dir $(PACKAGE_OUT)  --package.boot_mode=ospi

else ifeq ($(__PL_SET__), true)
	$(VPP) $(VPP_FLAGS) -l $(VPP_LDFLAGS) --temp_dir $(TEMP_DIR)  -o'$(BUILD_DIR)/kernel.link.xclbin' $(BINARY_CONTAINER_OBJS)
	$(VPP) -p $(BUILD_DIR)/kernel.link.xclbin --temp_dir $(TEMP_DIR) -t $(TARGET) --platform $(DEVICE) --package.out_dir $(PACKAGE_OUT) -o $(BUILD_DIR)/kernel.xclbin
else

endif

	cp $(TEMP_DIR)/reports/link/imp/impl_1_full_util_routed.rpt    ${BUILD_DIR}/report/  | true
	cp $(TEMP_DIR)/reports/link/imp/impl_1_kernel_util_routed.rpt  ${BUILD_DIR}/report/  | true
	cat $(TEMP_DIR)/link/vivado/vpl/runme.log |  grep scaled\ frequency >   ${BUILD_DIR}/clock.log | true





.PHONY: build
build: check-vitis  $(BINARY_CONTAINERS)

.PHONY: xclbin
xclbin: build


