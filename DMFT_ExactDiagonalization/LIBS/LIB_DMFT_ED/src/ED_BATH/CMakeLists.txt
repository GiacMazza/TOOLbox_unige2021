# DMFT_ED library
FILE(GLOB ED_BATH_SRC
  # ED_HLOC_DECOMPOSITION.f90  
  ED_BATH.f90
  ED_BATH_FUNCTIONS.f90
  ED_FIT_COMMON.f90
  ED_FIT_NORMAL.f90
  ED_FIT_HYBRID.f90
  ED_FIT_REPLICA.f90
  ED_BATH_FIT.f90
  )

ADD_LIBRARY(ED_BATH_LIB OBJECT  ${ED_BATH_SRC})
