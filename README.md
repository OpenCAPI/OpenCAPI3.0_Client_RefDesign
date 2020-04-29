# OpenCAPI3.0_Device_RefDesign

[OpenCAPI3.0 Wiki](https://github.com/OpenCAPI/OpenCAPI3.0_Client_RefDesign/wiki)

# Supported Cards
1. [Alphadata 9V3](https://www.alpha-data.com/dcp/products.php?product=adm-pcie-9v3)

# Supported AFUs
1. AFP

# Build AFU
```
vivado -mode batch -source create_project.tcl
```

The top module is in `board_support_packages/<CARD>/verilog/hdk_top/oc_fpga_top.v`

# For OC-Accel
This repository is also a submodule of OpenCAPI Acceleration Framework (OC-Accel). Check the README.md file of OC-Accel for more information.

# Ignore
This is a non-functional change to test the submodule/fork workflow
