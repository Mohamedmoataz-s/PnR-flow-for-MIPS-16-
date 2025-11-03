# RTL-to-GDSII Physical Design Flow - MIPS-16 Processor

This project demonstrates a complete ASIC RTL-to-GDSII physical design flow for a MIPS-16 processor core using industry-standard EDA tools. It implements a full production-style backend methodology including synthesis, T-shaped floorplanning, power grid construction, standard-cell placement, clock-tree synthesis, routing, post-route optimization, timing closure, and final GDS export. The flow achieves 500 MHz operating frequency with legal placement, balanced clock distribution, proper power routing with IR drop <2%, congestion-aware routing, and finished chip layout meeting all signoff requirements. Two design iterations explore power ring versus mesh-based power distribution strategies, demonstrating 2× frequency improvement (250→500 MHz) with only 2.1% area overhead. All design stages are documented and supported with analysis figures capturing IR drop distribution, cell density maps, pin density distribution, and clock tree routing structure. This repository serves as a practical learning and reference platform for students and VLSI engineers working on advanced physical design flows for processor cores, ensuring timing, power, and physical sign-off quality aligned with industry standards.

---

## 📋 Project Specifications

### RTL Design
- **Core**: MIPS-16 Processor

### Hard Requirements
- ✅ Pins on **metal4** and **metal5**
- ✅ Inputs on **upper and left** sides
- ✅ Outputs on **right and bottom** sides
- ✅ **T-shaped floorplan**
- ✅ **IR drop ≤ 2%**
- ✅ **Formality passing** (RTL vs pre-layout netlist and RTL vs post-layout netlist)

### Design Targets
- 🎯 **Challenge**: Achieve fastest frequency and smallest area
- 🎯 **Starting Point**: Clock period of 4ns (250 MHz), utilization 0.25
- 🎯 **Timing Constraints**: 
  - Input/Output delay: 30% of clock period
  - Clock uncertainty: 0.35 ps (tech node dependent)

---

## 📸 Flow Outputs & Design Analysis

### Trial #1 - Power Ring Configuration (250 MHz)

#### ⚡ IR Drop Analysis - Trial #1
![IR Drop Map Trial 1](![WhatsApp Image 2025-11-03 at 19 56 37_ee009535](https://github.com/user-attachments/assets/8909c9ff-6d8a-4e08-b255-2a643f474117)
)
*Shows voltage drop distribution with power ring configuration through metal 10, 9 and 7, 8, maintaining IR drop below 2% threshold.*

#### 📐 Cell Density Analysis - Trial #1
![Cell Density Map Trial 1](path/to/figure![WhatsApp Image 2025-11-03 at 02 21 51_132b3fea](https://github.com/user-attachments/assets/c25a497c-0f86-4a17-bfbc-17450d25bca1)
3.png)
*Shows standard cell distribution across the chip with 36979.32 μm² area and balanced placement density.*

#### 📌 Pin Density Analysis - Trial #1
![Pin Density Map Trial 1](path/to/fi![WhatsApp Image 2025-11-03 at 02 21 18_97bc0ae6](https://github.com/user-attachments/assets/69f14bc0-963d-4717-ab23-a1bac0ceb080)
gure5.png)
*Indicates pin distribution with inputs on upper and left sides, outputs on right and bottom sides per T-shaped floorplan specification.*

#### 🕒 Clock Tree Synthesis (CTS) - Trial #1
![CTS Routing Trial 1](path/to/f![WhatsApp Image 2025-11-03 at 02 20 40_eb708552](https://github.com/user-attachments/assets/aee2865b-a335-48c9-9dba-4a0362fdda1c)
igure7.png)
*Shows CTS buffers and clock routes with standard parameters achieving 250 MHz frequency and balanced clock skew.*

---

### Trial #2 - Mesh-Based Power Distribution (500 MHz) ⭐ **Optimal Design**

#### ⚡ IR Drop Analysis - Trial #2
![IR Drop Map Trial 2](path/to/figure2.png)
*Demonstrates improved voltage distribution with mesh-based power strategy and increased metal widths, achieving better power integrity.*

#### 📐 Cell Density Analysis - Trial #2
![Cell Density Map Trial 2](path/to/figure4.png)
*Displays optimized cell placement with 37769.34 μm² area supporting 2× frequency improvement with minimal congestion.*

#### 📌 Pin Density Analysis - Trial #2
![Pin Density Map Trial 2](path/to/figure6.png)
*Confirms maintained pin placement strategy on metal4 and metal5 layers with high-activity regions for routing optimization.*

#### 🕒 Clock Tree Synthesis (CTS) - Trial #2
![CTS Routing Trial 2](path/to/figure8.png)
*Displays optimized CTS with max fanout=5, max transition=0.3ns, buffer size 8, enabling 500 MHz operation with balanced delay.*

---

## 📊 Design Comparison Summary

| Metric | Trial #1 (Power Ring) | Trial #2 (Mesh-Based) ⭐ |
|--------|----------------------|-------------------------|
| **Frequency** | 250 MHz | **500 MHz** (2× improvement) |
| **Area** | **36979.32 μm²** | 37769.34 μm² (+2.1%) |
| **Power Strategy** | Power rings (M10/M9, M7/M8) + Metal 6 tapping | Mesh with increased metal widths & interleaving spaces |
| **CTS Max Fanout** | Default | 5 |
| **CTS Max Transition** | Default | 0.3 ns |
| **CTS Driving Cell** | Default | Buffer size 8 |
| **IR Drop** | <2% ✅ | <2% ✅ |
| **Signoff (PVR/Timing)** | Pass/Pass ✅ | Pass/Pass ✅ |
| **Formality Check** | Pass ✅ | Pass ✅ |

---

## 🎯 Key Success Factors

### Power Distribution Strategy
- ✅ **Mesh-based power distribution** instead of traditional power rings
- ✅ **Increased metal widths** with interleaving spaces for better current delivery
- ✅ **IR drop maintained <2%** across entire chip area

### Clock Tree Optimization
- ✅ **Reduced max fanout to 5** for better clock distribution
- ✅ **Max transition constraint of 0.3ns** for signal integrity
- ✅ **Buffer size 8** for CTS driving cells ensuring adequate drive strength

### Floorplan & Placement
- ✅ **T-shaped floorplan** meeting design specifications
- ✅ **Strategic pin placement** on metal4/metal5 layers
- ✅ **Balanced cell density** with minimal congestion hotspots

### Design Closure
- ✅ **Timing closure** at 500 MHz target frequency
- ✅ **Formality verification** passing for both pre and post-layout
- ✅ **Physical verification (PVR)** clean with no violations

---

## 🏆 Final Design Recommendation

**Trial #2** configuration provides the **best performance-area trade-off**, achieving:

- **500 MHz target frequency** (2× improvement over baseline)
- **Only 2.1% area penalty** (789.01 μm² difference from smallest design)
- **All signoff requirements met** (timing closure, power integrity, formality)
- **Production-ready quality** suitable for tape-out

### Performance Metrics
- **Frequency Achievement**: 500 MHz vs 250 MHz baseline = **100% improvement**
- **Area Efficiency**: 37769.34 μm² vs 36979.32 μm² = **2.1% overhead**
- **Power Integrity**: IR drop maintained well below 2% threshold
- **Clock Quality**: Balanced distribution with optimized skew and transition times

---

## 💡 Key Learnings

1. **Power Distribution Impact**: The choice between power rings and mesh-based distribution significantly affects achievable frequency. Mesh-based approach provides better current delivery enabling higher performance.

2. **CTS Parameter Tuning**: Aggressive CTS optimization (lower fanout, tighter transition constraints, larger buffers) is critical for high-frequency designs, with minimal area impact.

3. **Performance vs Area Trade-off**: A small area increase (2.1%) can enable substantial frequency improvements (2×), demonstrating the value of strategic area investment.

4. **Design Methodology**: Systematic exploration of design parameters through documented trials enables data-driven decision making for optimal PPA (Power-Performance-Area) balance.

---

## 🔧 Design Flow Summary

1. **RTL Synthesis** → Gate-level netlist generation
2. **Floorplanning** → T-shaped floorplan with strategic pin placement
3. **Power Planning** → Mesh-based power grid construction
4. **Placement** → Standard cell placement with density optimization
5. **Clock Tree Synthesis** → Optimized CTS with tight constraints
6. **Routing** → Congestion-aware detailed routing
7. **Post-Route Optimization** → Timing and signal integrity fixes
8. **Physical Verification** → DRC/LVS/IR drop analysis
9. **Timing Signoff** → STA verification at 500 MHz
10. **Formality Check** → RTL-to-GDS equivalence verification
11. **GDSII Export** → Final tape-out ready database

---

## 📚 Documentation Structure

```
project/
├── reports/
│   ├── trial1_timing_report.txt
│   ├── trial2_timing_report.txt
│   ├── trial1_power_report.txt
│   └── trial2_power_report.txt
├── figures/
│   ├── trial1_ir_drop.png
│   ├── trial2_ir_drop.png
│   ├── trial1_cell_density.png
│   ├── trial2_cell_density.png
│   ├── trial1_pin_density.png
│   ├── trial2_pin_density.png
│   ├── trial1_cts.png
│   └── trial2_cts.png
├── scripts/
│   ├── synthesis.tcl
│   ├── floorplan.tcl
│   ├── powerplan.tcl
│   ├── placement.tcl
│   ├── cts.tcl
│   └── route.tcl
└── README.md
```

---

## 🎓 Educational Value

This project serves as a comprehensive reference for:
- **Physical design engineers** learning advanced PD flows
- **Students** studying VLSI backend design methodologies
- **Design teams** exploring power distribution strategies
- **Researchers** investigating performance optimization techniques

---

## 📝 Conclusion

The project successfully demonstrates that **power distribution strategy significantly impacts both performance and area**. The mesh-based approach in Trial #2 achieved the target of highest frequency while maintaining acceptable area overhead, making it the **optimal solution for the MIPS-16 RTL-to-GDSII implementation**.

The documented methodology and results provide valuable insights for future physical design projects, highlighting the importance of systematic exploration and data-driven optimization in achieving production-quality chip designs.

---

## 📧 Contact & Contribution

For questions, suggestions, or collaboration opportunities, please open an issue or submit a pull request.

**Project Status**: ✅ Complete - Ready for tape-out

**Last Updated**: August 28, 2025

---

*This project demonstrates industry-standard physical design practices and serves as a learning resource for the VLSI design community.*
