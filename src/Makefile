TARGET = Brainfuck

# set your sdk path
CC = clang
SDK ?= /SDKs/iPhoneOS6.1.sdk

COMMON_FLAGS = -target armv7-apple-ios6.1 \
               -isysroot $(SDK) \
               -fobjc-arc

CFLAGS = $(COMMON_FLAGS) -c -I.
LDFLAGS = $(COMMON_FLAGS) \
          -framework Foundation \
          -framework UIKit \
          -framework CoreGraphics \
          -framework QuartzCore

SOURCES = main.m \
          AppDelegate.m \
          ViewController.m \
          ImageUtils.m \
          LeafyView.m \
          ScanlinesView.m \
          CustomButton.m \
          TapePointerView.m \
          MemoryCell.m

OBJECTS = $(SOURCES:.m=.o)
APP_BUNDLE = $(TARGET).app


all: app clobj

app: $(TARGET) Info.plist
	@mkdir -p $(APP_BUNDLE)
	@cp $(TARGET) Info.plist $(APP_BUNDLE)/
	@echo "APPL????" > $(APP_BUNDLE)/PkgInfo

$(TARGET): $(OBJECTS)
	@echo "	LD	$@"
	@$(CC) $(LDFLAGS) -o $@ $^
	@echo "	LDID	$(TARGET)"
	@ldid -S $(TARGET)

%.o: %.m
	@echo "	CC	$<"
	@$(CC) $(CFLAGS) -o $@ $<

clobj:
	@echo "	CLEAN"
	@rm -f $(TARGET) $(OBJECTS)

clean:
	@rm -rf $(APP_BUNDLE)

.PHONY: all app clean clobj
