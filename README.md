# OpenCAPI3.0_Device_RefDesign

[OpenCAPI3.0 Wiki](https://github.com/OpenCAPI/OpenCAPI3.0_Client_RefDesign/wiki)

# Goal
This repositery contains all necessary hardware description to use the OpenCAPI(OC) technology available in any Power9 processors.
It contains the TLx and DLx blocs, require to connect to the TL/DL of Power9

It can be used to prepare the code of an FPGA:
* either in standalone mode, to basically attach a card containing an FPGA to the Power9 OC link
* or as a submodule of OpenCAPI Acceleration Framework (OC-Accel).

In the latter, OC-Accel offers a way to program the FPGA without pain, using HDL langages or HLS (high level Synthesis).

OC-Accel doc can be found [here:](https://opencapi.github.io/oc-accel-doc/)


# Supported Cards
1. [Alphadata 9V3](https://www.alpha-data.com/dcp/products.php?product=adm-pcie-9v3)
2. [Alphadata 9H3 with default XCVU33P](https://www.alpha-data.com/dcp/products.php?product=adm-pcie-9h3)
3. [Alphadata 9H3 with XCVU35P](https://www.alpha-data.com/dcp/products.php?product=adm-pcie-9h3)
4. [Alphadata 9H7](https://www.alpha-data.com/dcp/products.php?product=adm-pcie-9h7)
5. [Bittware 250-SoC](https://www.bittware.com/fpga/250-soc/)

# Supported AFUs
* AFP

# Build AFU
```
vivado -mode batch -source create_project.tcl
```

The top module is in `board_support_packages/<CARD>/verilog/hdk_top/oc_fpga_top.v`

