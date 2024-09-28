//==- RISCVSchedNeoTechNeoRV1.td - NeoTech NeoRV1 Sched Defs -*- tablegen -*-=//
//
// Not actually part of the LLVM Project.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//

// This file is just for testing

// NeoRV1 is an out-of-order superscalar octal-issue core.
// FIXME: add V and Zkn extensions scheduling model
def NeoTechNeoRV1Model : SchedMachineModel {
  let MicroOpBufferSize = 64;
  let IssueWidth = 8;
  let MispredictPenalty = 9;
  let LoadLatency = 3;
  let CompleteModel = 0;
  let UnsupportedFeatures = [HasStdExtZksed, HasStdExtZksh, HasStdExtZkr,
                             HasStdExtZcmt, HasVInstructions];
}

// Branching
multiclass NeoRV1_Branching<ProcResourceKind BRU> {
  def : WriteRes<WriteJmp, [BRU]>;
  def : WriteRes<WriteJal, [BRU]>;
  def : WriteRes<WriteJalr, [BRU]>;
}

// Single-cycle integer arithmetic and logic
multiclass NeoRV1_IntALU<ProcResourceKind ALU> {
  def : WriteRes<WriteIALU, [ALU]>;
  def : WriteRes<WriteIALU32, [ALU]>;
  def : WriteRes<WriteShiftImm, [ALU]>;
  def : WriteRes<WriteShiftImm32, [ALU]>;
  def : WriteRes<WriteShiftReg, [ALU]>;
  def : WriteRes<WriteShiftReg32, [ALU]>;
}

// Pipelined integer multiplication
multiclass NeoRV1_IntMul<list<ProcResourceKind> Resources> {
  let Latency = 3 in {
    def : WriteRes<WriteIMul, Resources>;
    def : WriteRes<WriteIMul32, Resources>;
  }
}

// Common implementation for WriteIDiv and WriteIDiv32 sched writes.
multiclass NeoRV1_IntDivImpl<list<ProcResourceKind> Resources,
                           list<int> ReleaseCycles, int DivLatency,
                           SchedWrite DivWrite, SchedWrite RemWrite> {
  let Latency = DivLatency, ReleaseAtCycles = ReleaseCycles in {
   def : WriteRes<DivWrite, Resources>;
   def : WriteRes<RemWrite, Resources>;
  }
}

// Non-pipelined integer division
multiclass NeoRV1_IntDiv<list<ProcResourceKind> Resources,
                       list<int> ReleaseCycles,
                       int DivLatency> {
  defm : NeoRV1_IntDivImpl<Resources,
                         ReleaseCycles,
                         DivLatency,
                         WriteIDiv,
                         WriteIRem>;
}

multiclass NeoRV1_IntDiv32<list<ProcResourceKind> Resources,
                         list<int> ReleaseCycles,
                         int DivLatency> {
  defm : NeoRV1_IntDivImpl<Resources,
                         ReleaseCycles,
                         DivLatency,
                         WriteIDiv32,
                         WriteIRem32>;
}

multiclass NeoRV1_Bitmanip<ProcResourceKind BMU> {
  let Latency = 1 in {
    // Zba
    def : WriteRes<WriteSHXADD, [BMU]>;
    def : WriteRes<WriteSHXADD32, [BMU]>;
    // Zbb
    def : WriteRes<WriteRotateImm, [BMU]>;
    def : WriteRes<WriteRotateImm32, [BMU]>;
    def : WriteRes<WriteRotateReg, [BMU]>;
    def : WriteRes<WriteRotateReg32, [BMU]>;
    def : WriteRes<WriteCLZ, [BMU]>;
    def : WriteRes<WriteCLZ32, [BMU]>;
    def : WriteRes<WriteCTZ, [BMU]>;
    def : WriteRes<WriteCTZ32, [BMU]>;
    def : WriteRes<WriteCPOP, [BMU]>;
    def : WriteRes<WriteCPOP32, [BMU]>;
    def : WriteRes<WriteREV8, [BMU]>;
    def : WriteRes<WriteORCB, [BMU]>;
    def : WriteRes<WriteIMinMax, [BMU]>;
    // Zbs
    def : WriteRes<WriteSingleBit, [BMU]>;
    def : WriteRes<WriteSingleBitImm, [BMU]>;
    // Zbc
    def : WriteRes<WriteCLMUL, [BMU]>;
    def : WriteRes<WriteBEXT, [BMU]>;
    def : WriteRes<WriteBEXTI, [BMU]>;
  }
}

multiclass NeoRV1_ScalarCrypto<ProcResourceKind SCU> {
  let Latency = 1 in {
    // Zbkb
    def : WriteRes<WriteBREV8, [SCU]>;
    def : WriteRes<WritePACK, [SCU]>;
    def : WriteRes<WritePACK32, [SCU]>;
    def : WriteRes<WriteZIP, [SCU]>;
    // Zbkx
    def : WriteRes<WriteXPERM, [SCU]>;
  }
}

multiclass NeoRV1_IntPipeline<ProcResourceKind ALU_Any,
                            ProcResourceKind ALU_DIV_IS,
                            ProcResourceKind DIV,
                            ProcResourceKind ALU_MUL_IS,
                            ProcResourceKind MUL> {
  defm : NeoRV1_Branching<ALU_Any>;
  defm : NeoRV1_Bitmanip<ALU_Any>;
  defm : NeoRV1_ScalarCrypto<ALU_Any>;
  defm : NeoRV1_IntALU<ALU_Any>;
  defm : NeoRV1_IntMul<[ALU_MUL_IS, MUL]>;
  defm : NeoRV1_IntDiv<[ALU_DIV_IS, DIV],
                      /* ReleaseAtCycles */[1, 35],
                      /* Latency */ 35>;
  defm : NeoRV1_IntDiv32<[ALU_DIV_IS, DIV],
                        /* ReleaseAtCycles */[1, 19],
                        /* Latency */ 19>;
}

// Load/store instructions
multiclass NeoRV1_BasicMemory<ProcResourceKind LSU> {
  let Latency = 3 in {
    def : WriteRes<WriteSTB, [LSU]>;
    def : WriteRes<WriteSTH, [LSU]>;
    def : WriteRes<WriteSTW, [LSU]>;
    def : WriteRes<WriteSTD, [LSU]>;
    def : WriteRes<WriteLDB, [LSU]>;
    def : WriteRes<WriteLDH, [LSU]>;
    def : WriteRes<WriteLDW, [LSU]>;
    def : WriteRes<WriteLDD, [LSU]>;
    def : WriteRes<WriteFST32, [LSU]>;
    def : WriteRes<WriteFST64, [LSU]>;
    def : WriteRes<WriteFLD32, [LSU]>;
    def : WriteRes<WriteFLD64, [LSU]>;
  }
}

// Atomic memory
multiclass NeoRV1_AtomicMemory<ProcResourceKind LSU> {
  let Latency = 19 in {
    def : WriteRes<WriteAtomicLDW, [LSU]>;
    def : WriteRes<WriteAtomicLDD, [LSU]>;
  }
  let Latency = 21 in {
    def : WriteRes<WriteAtomicW, [LSU]>;
    def : WriteRes<WriteAtomicD, [LSU]>;
    def : WriteRes<WriteAtomicSTW, [LSU]>;
    def : WriteRes<WriteAtomicSTD, [LSU]>;
  }
}
multiclass NeoRV1_FPU<ProcResourceKind FPU_IS, ProcResourceKind FALU,
                    ProcResourceKind FMA, ProcResourceKind FDIVSQRT> {
  // FALU operations
  let Latency = 4 in {
    def : WriteRes<WriteFAdd32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFAdd64, [FPU_IS, FALU]>;
    def : WriteRes<WriteFSGNJ32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFSGNJ64, [FPU_IS, FALU]>;
    def : WriteRes<WriteFMinMax32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFMinMax64, [FPU_IS, FALU]>;

    def : WriteRes<WriteFCvtI32ToF32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFCvtI32ToF64, [FPU_IS, FALU]>;
    def : WriteRes<WriteFCvtI64ToF32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFCvtI64ToF64, [FPU_IS, FALU]>;
    def : WriteRes<WriteFCvtF32ToF64, [FPU_IS, FALU]>;
    def : WriteRes<WriteFCvtF64ToF32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFCvtF32ToI32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFCvtF32ToI64, [FPU_IS, FALU]>;
    def : WriteRes<WriteFCvtF64ToI32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFCvtF64ToI64, [FPU_IS, FALU]>;

    def : WriteRes<WriteFClass32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFClass64, [FPU_IS, FALU]>;

    def : WriteRes<WriteFCmp32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFCmp64, [FPU_IS, FALU]>;

    def : WriteRes<WriteFMovI32ToF32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFMovF32ToI32, [FPU_IS, FALU]>;
    def : WriteRes<WriteFMovI64ToF64, [FPU_IS, FALU]>;
    def : WriteRes<WriteFMovF64ToI64, [FPU_IS, FALU]>;
  }

  // FMA operations
  let Latency = 6 in {
    def : WriteRes<WriteFMul32, [FPU_IS, FMA]>;
    def : WriteRes<WriteFMul64, [FPU_IS, FMA]>;
    def : WriteRes<WriteFMA32, [FPU_IS, FMA]>;
    def : WriteRes<WriteFMA64, [FPU_IS, FMA]>;
  }

  def : WriteRes<WriteFDiv32, [FPU_IS, FDIVSQRT]> {
    let Latency = 16;
    let ReleaseAtCycles = [1, 15];
  }
  def : WriteRes<WriteFDiv64, [FPU_IS, FDIVSQRT]> {
    let Latency = 30;
    let ReleaseAtCycles = [1, 29];
  }

  def : WriteRes<WriteFSqrt32, [FPU_IS, FDIVSQRT]> {
    let Latency = 18;
    let ReleaseAtCycles = [1, 16];
  }
  def : WriteRes<WriteFSqrt64, [FPU_IS, FDIVSQRT]> {
    let Latency = 32;
    let ReleaseAtCycles = [1, 30];
  }
}

// Others
multiclass NeoRV1_Other {
  def : WriteRes<WriteCSR, []>;
  def : WriteRes<WriteNop, []>;

  def : InstRW<[WriteIALU], (instrs COPY)>;
}

// Unsupported scheduling classes for SCR7.
multiclass NeoRV1_Unsupported {
  defm : UnsupportedSchedSFB;
  defm : UnsupportedSchedV;
  defm : UnsupportedSchedXsfvcp;
  defm : UnsupportedSchedZabha;
  defm : UnsupportedSchedZfa;
  defm : UnsupportedSchedZfh;
  defm : UnsupportedSchedZvk;
}


// Bypasses (none)
multiclass NeoRV1_NoReadAdvances {
  def : ReadAdvance<ReadJmp, 0>;
  def : ReadAdvance<ReadJalr, 0>;
  def : ReadAdvance<ReadCSR, 0>;
  def : ReadAdvance<ReadStoreData, 0>;
  def : ReadAdvance<ReadMemBase, 0>;
  def : ReadAdvance<ReadIALU, 0>;
  def : ReadAdvance<ReadIALU32, 0>;
  def : ReadAdvance<ReadShiftImm, 0>;
  def : ReadAdvance<ReadShiftImm32, 0>;
  def : ReadAdvance<ReadShiftReg, 0>;
  def : ReadAdvance<ReadShiftReg32, 0>;
  def : ReadAdvance<ReadIDiv, 0>;
  def : ReadAdvance<ReadIDiv32, 0>;
  def : ReadAdvance<ReadIRem, 0>;
  def : ReadAdvance<ReadIRem32, 0>;
  def : ReadAdvance<ReadIMul, 0>;
  def : ReadAdvance<ReadIMul32, 0>;
  def : ReadAdvance<ReadAtomicWA, 0>;
  def : ReadAdvance<ReadAtomicWD, 0>;
  def : ReadAdvance<ReadAtomicDA, 0>;
  def : ReadAdvance<ReadAtomicDD, 0>;
  def : ReadAdvance<ReadAtomicLDW, 0>;
  def : ReadAdvance<ReadAtomicLDD, 0>;
  def : ReadAdvance<ReadAtomicSTW, 0>;
  def : ReadAdvance<ReadAtomicSTD, 0>;
  def : ReadAdvance<ReadSHXADD, 0>;
  def : ReadAdvance<ReadSHXADD32, 0>;
  def : ReadAdvance<ReadRotateImm, 0>;
  def : ReadAdvance<ReadRotateImm32, 0>;
  def : ReadAdvance<ReadRotateReg, 0>;
  def : ReadAdvance<ReadRotateReg32, 0>;
  def : ReadAdvance<ReadCLZ, 0>;
  def : ReadAdvance<ReadCLZ32, 0>;
  def : ReadAdvance<ReadCTZ, 0>;
  def : ReadAdvance<ReadCTZ32, 0>;
  def : ReadAdvance<ReadCPOP, 0>;
  def : ReadAdvance<ReadCPOP32, 0>;
  def : ReadAdvance<ReadREV8, 0>;
  def : ReadAdvance<ReadORCB, 0>;
  def : ReadAdvance<ReadIMinMax, 0>;
  def : ReadAdvance<ReadCLMUL, 0>;
  def : ReadAdvance<ReadBREV8, 0>;
  def : ReadAdvance<ReadPACK, 0>;
  def : ReadAdvance<ReadPACK32, 0>;
  def : ReadAdvance<ReadZIP, 0>;
  def : ReadAdvance<ReadXPERM, 0>;
  def : ReadAdvance<ReadSingleBit, 0>;
  def : ReadAdvance<ReadSingleBitImm, 0>;
  def : ReadAdvance<ReadFStoreData, 0>;
  def : ReadAdvance<ReadFMemBase, 0>;
  def : ReadAdvance<ReadFAdd32, 0>;
  def : ReadAdvance<ReadFAdd64, 0>;
  def : ReadAdvance<ReadFMul32, 0>;
  def : ReadAdvance<ReadFMul64, 0>;
  def : ReadAdvance<ReadFMA32, 0>;
  def : ReadAdvance<ReadFMA32Addend, 0>;
  def : ReadAdvance<ReadFMA64, 0>;
  def : ReadAdvance<ReadFMA64Addend, 0>;
  def : ReadAdvance<ReadFDiv32, 0>;
  def : ReadAdvance<ReadFDiv64, 0>;
  def : ReadAdvance<ReadFSqrt32, 0>;
  def : ReadAdvance<ReadFSqrt64, 0>;
  def : ReadAdvance<ReadFCmp32, 0>;
  def : ReadAdvance<ReadFCmp64, 0>;
  def : ReadAdvance<ReadFSGNJ32, 0>;
  def : ReadAdvance<ReadFSGNJ64, 0>;
  def : ReadAdvance<ReadFMinMax32, 0>;
  def : ReadAdvance<ReadFMinMax64, 0>;
  def : ReadAdvance<ReadFCvtF32ToI32, 0>;
  def : ReadAdvance<ReadFCvtF32ToI64, 0>;
  def : ReadAdvance<ReadFCvtF64ToI32, 0>;
  def : ReadAdvance<ReadFCvtF64ToI64, 0>;
  def : ReadAdvance<ReadFCvtI32ToF32, 0>;
  def : ReadAdvance<ReadFCvtI32ToF64, 0>;
  def : ReadAdvance<ReadFCvtI64ToF32, 0>;
  def : ReadAdvance<ReadFCvtI64ToF64, 0>;
  def : ReadAdvance<ReadFCvtF32ToF64, 0>;
  def : ReadAdvance<ReadFCvtF64ToF32, 0>;
  def : ReadAdvance<ReadFMovF32ToI32, 0>;
  def : ReadAdvance<ReadFMovI32ToF32, 0>;
  def : ReadAdvance<ReadFMovF64ToI64, 0>;
  def : ReadAdvance<ReadFMovI64ToF64, 0>;
  def : ReadAdvance<ReadFClass32, 0>;
  def : ReadAdvance<ReadFClass64, 0>;
}

let SchedModel = NeoTechNeoRV1Model in {
  // Integer pipeline has two reservation stations with single issue port
  // each. Every station has eight entries:
  // First station:
  //   - ALU (+ bitmanip and scalar crypto)
  //   - Pipelined Multiplier (3 stage)
  // Second station:
  //   - ALU (+ bitmanip and scalar crypto)
  //   - Non-pipelined divider (other units are not blocked)
  def NeoRV1_ALU_MUL_IS : ProcResource<1> { let BufferSize = 8; }
  def NeoRV1_ALU_DIV_IS : ProcResource<1> { let BufferSize = 8; }
  def NeoRV1_ALU_Any : ProcResGroup<[NeoRV1_ALU_MUL_IS, NeoRV1_ALU_DIV_IS]>;
  def NeoRV1_MUL : ProcResource<1> { let BufferSize = 1; }
  def NeoRV1_DIV : ProcResource<1> { let BufferSize = 1; }

  defm : NeoRV1_IntPipeline<NeoRV1_ALU_Any,
                         NeoRV1_ALU_DIV_IS, NeoRV1_DIV,
                         NeoRV1_ALU_MUL_IS, NeoRV1_MUL>;

  // SCR7 single-issue LSU with sixteen entries.
  def NeoRV1_LSU : ProcResource<1> { let BufferSize = 16; }
  defm : NeoRV1_BasicMemory<NeoRV1_LSU>;
  defm : NeoRV1_AtomicMemory<NeoRV1_LSU>;

  // FPU has one issue slot with eight entries:
  //   - FP ALU
  //   - FMA
  //   - Non-pipelined FDIV/FSQRT
  def NeoRV1_FPU_IS : ProcResource<1> { let BufferSize = 8; }
  def NeoRV1_FALU : ProcResource<1> { let BufferSize = 1; }
  def NeoRV1_FMA : ProcResource<1> { let BufferSize = 1; }
  def NeoRV1_FDIVSQRT : ProcResource<1> { let BufferSize = 1; }
  defm : NeoRV1_FPU<NeoRV1_FPU_IS, NeoRV1_FALU, NeoRV1_FMA, NeoRV1_FDIVSQRT>;

  defm : NeoRV1_Other;
  defm : NeoRV1_Unsupported;
  defm : NeoRV1_NoReadAdvances;
}
