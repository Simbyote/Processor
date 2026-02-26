`default_nettype none
/* spi.sv
 * Purpose:
 *  Interfaces with the SPI master module to 
 *  transmit data from main memory.
 *
 * Functions:
 * - Coordinate SPI transactions via memory-mapped access.
 * - Transfer data as directed by SPI instructions.
 *
 * Modules:
 * - spi: SPI interface module.
 *
 * Notes:
 * - Does not implement SPI protocol logic internally.
 * - Relies on a provided SPI module (S25FL204K - 4-Mbit 3.0 V SPI Flash Memory)
 */
`default_nettype wire