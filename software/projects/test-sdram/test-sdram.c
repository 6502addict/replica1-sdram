// Memory Test for SDRAM E000-EFFF
// Compile: cl65 -t replica1 --start-addr 0x0300 memtest.c -o memtest.bin

#include <stdint.h>
#include <stdbool.h>

// Apple 1 I/O addresses
#define DSP     (*(volatile uint8_t*)0xD012)  // Display output
#define DSP_CR  (*(volatile uint8_t*)0xD013)  // Display control

// Test range
#define TEST_START  0xE000
#define TEST_END    0xEFFF
#define TEST_SIZE   (TEST_END - TEST_START + 1)

// Simple delay
void delay(void) {
    volatile uint16_t i;
    for (i = 0; i < 1000; i++);
}

// Print character to display
void putch(char c) {
    DSP = c | 0x80;  // Set high bit for Apple 1
    delay();
}

// Print string
void print(const char* s) {
    while (*s) {
        putch(*s++);
    }
}

// Print hex byte
void printhex8(uint8_t val) {
    const char hex[] = "0123456789ABCDEF";
    putch(hex[val >> 4]);
    putch(hex[val & 0x0F]);
}

// Print hex word
void printhex16(uint16_t val) {
    printhex8(val >> 8);
    printhex8(val & 0xFF);
}

// Memory test - write pattern and verify
bool test_pattern(uint8_t pattern) {
    volatile uint8_t* mem = (volatile uint8_t*)TEST_START;
    uint16_t i;
    
    // Write pattern
    for (i = 0; i < TEST_SIZE; i++) {
        mem[i] = pattern;
    }
    
    // Verify pattern
    for (i = 0; i < TEST_SIZE; i++) {
        if (mem[i] != pattern) {
            print("\r\nFAIL AT ");
            printhex16(TEST_START + i);
            print(" EXP:");
            printhex8(pattern);
            print(" GOT:");
            printhex8(mem[i]);
            return false;
        }
    }
    
    return true;
}

void main(void) {
    uint16_t pass_count = 0;
    uint16_t fail_count = 0;
    
    print("\r\nSDRAM TEST E000-EFFF\r\n");
    
    while (1) {
        bool pass = true;
        
        // Test with 0x55 (01010101)
        if (!test_pattern(0x55)) {
            pass = false;
        }
        
        // Test with 0xAA (10101010) - shifted pattern
        if (!test_pattern(0xAA)) {
            pass = false;
        }
        
        // Test with 0x00
        if (!test_pattern(0x00)) {
            pass = false;
        }
        
        // Test with 0xFF
        if (!test_pattern(0xFF)) {
            pass = false;
        }
        
        // Update counters
        if (pass) {
            pass_count++;
        } else {
            fail_count++;
        }
        
        // Display results
        print("\r\nPASS:");
        printhex16(pass_count);
        print(" FAIL:");
        printhex16(fail_count);
        
        delay();
    }
}
