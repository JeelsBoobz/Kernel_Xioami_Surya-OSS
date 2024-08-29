#!/bin/bash
#
# Compile script for Deluxe Kernel (DEXK)
# Copyright (C)2022 Ardany Jolón
SECONDS=0 # builtin bash timer
KERNEL_PATH=$PWD
TC_DIR="$HOME/tc/clang-15"
GCC_64_DIR="$HOME/tc/aarch64-linux-android-4.9"
GCC_32_DIR="$HOME/tc/arm-linux-androideabi-4.9"
AK3_DIR="$HOME/tc/AnyKernel3"
DEFCONFIG="surya_defconfig"
export PATH="$TC_DIR/bin:$PATH"

# Change Kernel Name
sed -i "s|CONFIG_LOCALVERSION=.*|CONFIG_LOCALVERSION=\"-JeelsBoobz-KSU\"|g" "arch/arm64/configs/surya_defconfig"

# Install needed tools
if [[ $1 = "-t" || $1 = "--tools" ]]; then
	git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 $HOME/tc/aarch64-linux-android-4.9
	git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 $HOME/tc/arm-linux-androideabi-4.9
	git clone -b surya https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 $HOME/tc/clang-15 --depth=1
fi

# Regenerate defconfig file
if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
fi

# Make a clean build
if [[ $1 = "-c" || $1 = "--clean" ]]; then
	rm -rf out
fi

if [[ $1 = "-b" || $1 = "--build" ]]; then
	mkdir -p out
	make O=out ARCH=arm64 $DEFCONFIG
	echo -e ""
	echo -e ""
	echo -e "*****************************"
	echo -e "**                         **"
	echo -e "** Starting compilation... **"
	echo -e "**                         **"
	echo -e "*****************************"
	echo -e ""
	echo -e ""
	make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-android- CROSS_COMPILE_ARM32=$GCC_32_DIR/bin/arm-linux-androideabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz dtbo.img

	kernel="out/arch/arm64/boot/Image.gz"
	dtb="out/arch/arm64/boot/dts/qcom/sdmmagpie.dtb"
	dtbo="out/arch/arm64/boot/dtbo.img"

	if [ -f "$kernel" ] && [ -f "$dtb" ] && [ -f "$dtbo" ]; then
		rm *.zip 2>/dev/null
		# Set kernel name and version
		KERNELVERSION="$(cat $KERNEL_PATH/Makefile | grep VERSION | head -n 1 | sed "s|.*=||1" | sed "s| ||g")"
		KERNELPATCHLEVEL="$(cat $KERNEL_PATH/Makefile | grep PATCHLEVEL | head -n 1 | sed "s|.*=||1" | sed "s| ||g")"
		KERNELSUBLEVEL="$(cat $KERNEL_PATH/Makefile | grep SUBLEVEL | head -n 1 | sed "s|.*=||1" | sed "s| ||g")"
		REVISION=v$KERNELVERSION.$KERNELPATCHLEVEL.$KERNELSUBLEVEL
		ZIPNAME=""$REVISION"-JeelsBoobz-POCO_X3_NFC-$(date '+%Y%m%d-%H%M').zip"
		echo -e ""
		echo -e ""
		echo -e "********************************************"
		echo -e "\nKernel compiled succesfully! Zipping up...\n"
		echo -e "********************************************"
		echo -e ""
		echo -e ""
	if [ -d "$AK3_DIR" ]; then
		cp -r $AK3_DIR AnyKernel3
	elif ! git clone -q https://github.com/Ardjlon/AnyKernel3 -b surya; then
			echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
	fi
		cp $kernel $dtbo AnyKernel3
		cp $dtb AnyKernel3/dtb
		rm -rf out/arch/arm64/boot
		cd AnyKernel3
		git checkout surya &> /dev/null
		zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
		cd ..
		rm -rf AnyKernel3

	# Upload to SourceForge, only works if you use -b -s
        if [[ $2 = "-s" || $2 = "--share" ]]; then
                CHAT_ID="-1001797680423" # ChatID
                API="7475306888:AAFCsgXZ5FGVm24v2b6vpZkMclTHdiC5R-A" # API bot token
                IMAGE="https://images.gamebanana.com/img/ss/mods/6655d87bbcd3d.jpg"

                curl \
                -F chat_id="$CHAT_ID" \
                -F "parse_mode=Markdown" \
                -F caption="Put your changelog here and link in mardkdown style" \
                -F photo="$IMAGE" \
                https://api.telegram.org/bot"$API"/sendPhoto
        fi

        echo -e ""
        echo -e ""
        echo -e "************************************************************"
        echo -e "**                                                        **"
        echo -e "**   File name: $ZIPNAME   **"
        echo -e "**   Build completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)!    **"
        echo -e "**                                                        **"
        echo -e "************************************************************"
        echo -e ""
        echo -e ""
	else
        echo -e ""
        echo -e ""
        echo -e "*****************************"
        echo -e "**                         **"
        echo -e "**   Compilation failed!   **"
        echo -e "**                         **"
        echo -e "*****************************"
	fi
	fi
