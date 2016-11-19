CC=arm-none-eabi-gcc
COMMON_FLAGS = -mthumb -mcpu=cortex-m0plus -Os -g
CDEFINES = -D__SAMD21G18A__
WFLAGS = \
-Wall -Wstrict-prototypes \
-Werror-implicit-function-declaration -Wpointer-arith -std=gnu99 \
-ffunction-sections -fdata-sections -Wchar-subscripts -Wcomment -Wformat=2 \
-Wimplicit-int -Wmain -Wparentheses -Wsequence-point -Wreturn-type -Wswitch \
-Wtrigraphs -Wunused -Wuninitialized -Wunknown-pragmas -Wfloat-equal -Wundef \
-Wbad-function-cast -Wwrite-strings -Waggregate-return \
-Wformat -Wmissing-format-attribute \
-Wno-deprecated-declarations -Wpacked -Wredundant-decls -Wnested-externs \
-Wlong-long -Wunreachable-code -Wcast-align \
-Wno-overflow -Wno-shadow -Wno-attributes -Wno-packed -Wno-pointer-sign -Werror
CFLAGS = $(COMMON_FLAGS) \
-x c -c -pipe -nostdlib \
--param max-inline-insns-single=500 \
-fno-strict-aliasing -fdata-sections -ffunction-sections -mlong-calls \
$(WFLAGS) $(CDEFINES)

LDFLAGS= $(COMMON_FLAGS) \
-Wall -Wl,--cref -Wl,--check-sections -Wl,--gc-sections -Wl,--unresolved-symbols=report-all -Wl,--warn-common \
-Wl,--warn-section-align -Wl,--warn-unresolved-symbols \
-save-temps  -T./asf/sam0/utils/linker_scripts/samd21/gcc/samd21j18a_flash.ld \
--specs=nano.specs --specs=nosys.specs 
BUILD_PATH=build
INCLUDES = -I. -I./preprocessor 
INCLUDES += -I./asf/sam0/utils/cmsis/samd21/include -I./asf/thirdparty/CMSIS/Include -I./asf/sam0/utils/cmsis/samd21/source
INCLUDES += -I./asf/common
SOURCES = main.c sam_ba_monitor.c startup_samd21.c \
usart_sam_ba.c cdc_enumerate.c uart_driver.c \
interrupt_sam_nvic.c msc.c fat.c
 
OBJECTS = $(addprefix $(BUILD_PATH)/, $(SOURCES:.c=.o))

NAME=uf2-bootloader
EXECUTABLE=$(BUILD_PATH)/$(NAME).bin

all: dirs $(EXECUTABLE) build/uf2conv

r: run
b: burn
l: logs

burn: all
	sh scripts/openocd.sh \
	-c "telnet_port disabled; init; halt; at91samd bootloader 0; program {{build/uf2-bootloader.bin}} verify reset; shutdown "

run: burn wait logs

wait:
	sleep 5

logs:
	sh scripts/getlogs.sh

dirs:
	-@mkdir $(BUILD_PATH)
	
$(EXECUTABLE): $(OBJECTS) 
	$(CC) -L$(BUILD_PATH) $(LDFLAGS) -Wl,-Map,$(BUILD_PATH)/$(NAME).map -o $(NAME).elf $(OBJECTS)
	arm-none-eabi-objcopy -O binary $(NAME).elf $@
	@arm-none-eabi-size $(NAME).elf

$(BUILD_PATH)/%.o: %.c
	@echo "$<"
	@$(CC) $(CFLAGS) $(BLD_EXTA_FLAGS) $(INCLUDES) $< -o $@

build/uf2conv:	uf2conv.c
	cc -W -Wall -o $@ uf2conv.c

clean:
	rm -rf $(EXECUTABLE) $(BUILD_PATH) $(NAME).elf



