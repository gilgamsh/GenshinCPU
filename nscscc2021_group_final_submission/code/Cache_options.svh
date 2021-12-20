`ifndef CACHE_OPTIONS_SVH
`define CACHE_OPTIONS_SVH

/**
    Options to control optional components to be compiled
    These options are used to speed up compilation when debugging

**/


`define CPU_PERFORMANCE      1
`define CPU_DELAYED_BRANCH   `CPU_PERFORMANCE

// `define TLB_ENTRIES_NUM      16
`define TLB_ENTRIES_NUM      8
`define CACHE_WAY_SIZE       4 * 1024        // 4KB 

`define ICACHE_LINE_WORD     16
`define ICACHE_SET_ASSOC     2
`define ICACHE_SIZE          CACHE_WAY_SIZE * ICACHE_SET_ASSOC  // 4KB* ASSOC
  

`define DCACHE_LINE_WORD     16
`define DCACHE_SET_ASSOC     2
`define DCACHE_SIZE          CACHE_WAY_SIZE * DCACHE_SET_ASSOC  // 4KB* ASSOC

`endif
