#include <device/device_config.h>
#include "mathops_kernel.h"

extern "C" {

  /** Fortran wrapper for opchsign \f$ a = -a \f$ */
  void cuda_opchsign(void *a1, void *a2, void *a3, int *gdim, int *n) {
    
    const dim3 nthrds(1024, 1, 1);
    const dim3 nblcks(((*n)+1024 - 1)/ 1024, 1, 1);
    
    opchsign_kernel<real>
      <<<nblcks, nthrds>>>((real *) a1, (real *) a2, (real *) a3,
			   *gdim, *n);
  }

  /** Fortran wrapper for opcolv \f$ a = a * c \f$ */
  void cuda_opcolv(void *a1, void *a2, void *a3, void *c, int *gdim, int *n) {

    const dim3 nthrds(1024, 1, 1);
    const dim3 nblcks(((*n)+1024 - 1)/ 1024, 1, 1);
    
    opcolv_kernel<real>
      <<<nblcks, nthrds>>>((real *) a1, (real *) a2, (real *) a3, 
			   (real *) c, *gdim, *n);
    
  }

  /** Fortran wrapper for opcolv3c \f$ a(i) = b(i) * c(i) * d \f$ */
  void cuda_opcolv3c(void *a1, void *a2, void *a3, void *b1, void *b2, void *b3,
		    void *c, real *d, int *gdim, int *n) {

    const dim3 nthrds(1024, 1, 1);
    const dim3 nblcks(((*n)+1024 - 1)/ 1024, 1, 1);
    
    opcolv3c_kernel<real>
      <<<nblcks, nthrds>>>((real *) a1, (real *) a2, (real *) a3,
			   (real *) b1, (real *) b2, (real *) b3,
			   (real *) c, *d, *gdim, *n);

  }

  /** Fortran wrapper for opadd2cm \f$ a(i) = a + b(i) * c \f$ */
  void cuda_opadd2cm(void *a1, void *a2, void *a3, 
		    void *b1, void *b2, void *b3, real *c, int *gdim, int *n) {

    const dim3 nthrds(1024, 1, 1);
    const dim3 nblcks(((*n)+1024 - 1)/ 1024, 1, 1);
    
    opadd2cm_kernel<real>
      <<<nblcks, nthrds>>>((real *) a1, (real *) a2, (real *) a3,
			   (real *) b1, (real *) b2, (real *) b3,
			   *c, *gdim, *n);

  }

  /** Fortran wrapper for opadd2col \f$ a(i) = a + b(i) * c(i) \f$ */
  void cuda_opadd2col(void *a1, void *a2, void *a3, 
		     void *b1, void *b2, void *b3, void *c, int *gdim, int *n) {

    const dim3 nthrds(1024, 1, 1);
    const dim3 nblcks(((*n)+1024 - 1)/ 1024, 1, 1);
    
    opadd2col_kernel<real>
      <<<nblcks, nthrds>>>((real *) a1, (real *) a2, (real *) a3,
			   (real *) b1, (real *) b2, (real *) b3,
			   (real *) c, *gdim, *n);
    
  }

}