################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_SRCS += \
../proj01.s 

OBJS += \
./proj01.o 

S_DEPS += \
./proj01.d 


# Each subdirectory must supply rules for building sources it contributes
proj01.o: ../proj01.s
	arm-none-eabi-gcc -mcpu=cortex-m0plus -g3 -c -x assembler-with-cpp -MMD -MP -MF"proj01.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@" "$<"

