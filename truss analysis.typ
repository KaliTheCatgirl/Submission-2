// Raw dead load values for each member (D_sw)
#let D_sw = (
  AB: 0.797,
  BC: 0.614,
  CD: 0.297,
  DE: 0.509,
  EF: 0.443,
  FG: 0.443,
  GH: 0.531,
  HI: 0.531,
  IJ: 0.443,
  JK: 0.443,
  KL: 0.509,
  LM: 0.297,
  MN: 0.614,
  NO: 0.797,
  B-A-: 0.297,
  A-Z: 0.443,
  ZY: 0.226,
  YX: 0.443,
  XW: 0.531,
  WV: 0.443,
  VU: 0.443,
  UT: 0.531,
  TS: 0.443,
  SR: 0.443,
  RQ: 0.443,
  QP: 0.297,
  AB-: 1.435,
  BB-: 0.517,
  B-C: 2.018,
  CA-: 0.593,
  A-D: 1.760,
  DZ: 0.517,
  ZE: 1.637,
  EY: 0.347,
  YF: 1.224,
  FX: 0.263,
  XG: 1.027,
  GW: 0.263,
  WH: 0.680,
  HV: 0.263,
  HU: 0.680,
  UI: 0.263,
  IT: 1.027,
  TJ: 0.263,
  JS: 1.224,
  SK: 0.347,
  KR: 1.637,
  RL: 0.517,
  LQ: 1.760,
  QM: 0.593,
  MP: 2.018,
  PN: 0.517,
  PO: 1.435,
).pairs().map(p => (p.at(0): p.at(1) * 1.25)).sum();

// Calculation of point dead loads (D_j) for each point. Each string is a list, with the point name first, and with every affecting member following.
// Each string is split and indexed with the raw member dead loads to calculate the D_j values.
#let D_j = (
  "A,AB,AB-",
  "B,AB,BB-,BC",
  "C,BC,B-C,CA-,CD",
  "D,CD,A-D,DZ,DE",
  "E,DE,ZE,EY,EF",
  "F,EF,YF,FX,FG",
  "B-,AB-,BB-,B-A-,B-C",
  "A-,B-A-,CA-,A-D,A-Z",
  "Z,A-Z,DZ,ZE,ZY",
  "Y,ZY,EY,YF,YX",
  "X,YX,FX,XG,XW",
  "G,FG,XG,GW,GH",
  "W,XW,GW,WH,WV",
  "H,GH,WH,HV,HU,HI",
  "V,WV,VU,HV"
).map(seq => {
  let (name, ..other) = seq.split(",")
  ((name): other.map(key => D_sw.at(key)).sum() / -2)
}).sum()

// Variables
#let snow_load_per_joint = -160.3563
#let snow_load = snow_load_per_joint * 15
#let total_dead_load = calc.round(D_sw.values().sum(), digits: 10)
#let joist_height = 10 / 3
#let joist_width = 40 / 14
#let joist_diagonal = calc.sqrt(joist_height * joist_height + joist_width * joist_width)

// Trigonometry constants for calculation and display
#let diag2y = joist_height / joist_diagonal
#let diag2y_s = [$#calc.round(joist_height, digits: 3) / #calc.round(joist_diagonal, digits: 3)$]

#let y2diag = joist_diagonal / joist_height
#let y2diag_s = [$#calc.round(joist_diagonal, digits: 3) / #calc.round(joist_height, digits: 3)$]

#let diag2x = joist_width / joist_diagonal
#let diag2x_s = [$#calc.round(joist_width, digits: 3) / #calc.round(joist_diagonal, digits: 3)$]

#let x2diag = joist_diagonal / joist_width
#let x2diag_s = [$#calc.round(joist_diagonal, digits: 3) / #calc.round(joist_width, digits: 3)$]

// Truss analysis
#let A_y = -snow_load / 2 + total_dead_load / 2
$ O_y = A_y = S + sum D_(s w) = #(-snow_load / 2) + #total_dead_load/2 = #A_y $

#let AB- = (A_y + snow_load_per_joint - D_j.A) * y2diag
$ A B' + A_y + P - D_j_A = 0, A B' = #y2diag_s A B'_y -> A B' = #y2diag_s (A_y + P - D_j_A) = #AB- $

#let AB = -AB- * diag2x
$ A B + A B'_y = 0 -> arrow(A B) = #diag2x_s A B' = -#diag2x_s (A B_y) = #AB $

#let BC = -AB
$ B C + A B = 0 -> B C = -A B = #BC $

#let BB- = snow_load_per_joint - D_j.B-
$ B B' + P + D_j_B' = 0 -> B B' = #BB- $

#let B-C = -(AB- * diag2y + BB- - D_j.B-) * y2diag 
$ B'C = #y2diag_s (B C_y - D_j_B') = -#y2diag_s (A B'_y + B B' - D_j_B') = #B-C $

#let B-A- = -AB- * diag2x - B-C * diag2x
$ B'A' = -A B'_x - B'C_x = #B-A- $

#let CA- = -diag2y * B-C - D_j.C + snow_load_per_joint
$ C A' = -B'C_y - D_j_C = -#diag2y_s (B'C) - D_j_C = #CA- $

#let CD = -BC - B-C * diag2x
$ C D + B C + B'C_x + D_j_C = 0 -> C D = #CD $

#let A-D = -y2diag * (CA- + D_j.A-)
$ A'D_y + C A' + D_j_A' = 0 -> A'D = -#y2diag_s (C A' + D_j_A') = #A-D $

#let A-Z = -diag2x * A-D + B-A-
$ A'Z - A'B' + A'D_x = 0 -> A'Z = A'B' - #diag2x_s A'D = #A-Z $

#let DZ = -diag2y * A-D + snow_load_per_joint - D_j.D
$ D Z + P + A'D_y + D_j_D = 0 -> D Z = -#diag2y_s A'D - P - D_j_D = #DZ $

#let DE = A-D * diag2x - CD
$ D E + C D - A'D_x = 0 -> D E = #diag2x_s A'D - C D = #DE $

#let ZE = -y2diag * (DZ + D_j.Z)
$ Z E_y + D Z + D_j_Z = 0 -> Z E = -#y2diag_s (D Z + D_j_Z) = #ZE $

#let ZY = -diag2x * ZE - A-Z
$ Z Y + A'Z + Z E_x = 0 -> Z Y = -#diag2x_s Z E - A'Z - D_j_Z = #ZY $

#let EY = -diag2y * ZE - D_j.E + snow_load_per_joint
$ E Y + Z E_y + D_j_E + P = 0 -> E Y = -#diag2y_s Z E - D_j_E - P = #EY $

#let EF = -diag2x * ZE + DE
$ E F - D E + Z E_x = 0 -> E F = -#diag2x_s Z E - D E = #EF $

#let YF = -y2diag * (EY + D_j.Y)
$ Y F_y + E Y + D_j_Y = 0 -> Y F = -#y2diag_s (E Y + D_j_Y) = #YF $

#let FX = -diag2y * YF + snow_load_per_joint - D_j.F
$ F X + Y F_y + P + D_j_F = 0 -> F X = -#diag2y_s Y F - P - D_j_F = #FX $

#let FG = -diag2x * YF - EF
$ F G + E F + Y F_x = 0 -> F G = -#diag2x_s Y F - E F = #FG $

#let XG = -y2diag * (FX + D_j.X)
$ X G_y + F X + D_j_X = 0 -> X G = -#y2diag_s (F X + D_j_X) = #XG $

#let YX = -diag2x * YF - ZY
$ Y X + Z Y + Y F_x = 0 -> Y X = -#diag2x_s Y F - Z Y = #YX $

#let XW = -diag2x * XG - YX
$ X W + Y X + X G_x = 0 -> X W = -#diag2x_s X G - Y X = #XW $

#let GH = -diag2x * XG - FG
$ G H + F G + X G_x = 0 -> G H = -#diag2x_s X G - F G = #GH $

#let GW = -diag2y * XG + snow_load_per_joint - D_j.G
$ G W + X G_y + P + D_j_G = 0 -> G W = -#diag2y_s X G - P - D_j_G = #GW $

#let WH = -y2diag * (GW + D_j.W)
$ W H_y + G W + D_j_W = 0 -> W H = -#y2diag_s (G W + D_j_W) = #WH $

#let WV = -diag2x * WH - XW
$ W V + X W + W H_x = 0 -> W V = -#diag2x_s W H - X W = #WV $

#let HV = D_j.V
$ H V + D_j_V = 0 -> H V = -D_j_V = #HV $
