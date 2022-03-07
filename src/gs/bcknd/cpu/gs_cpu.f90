! Copyright (c) 2020-2022, The Neko Authors
! All rights reserved.
!
! Redistribution and use in source and binary forms, with or without
! modification, are permitted provided that the following conditions
! are met:
!
!   * Redistributions of source code must retain the above copyright
!     notice, this list of conditions and the following disclaimer.
!
!   * Redistributions in binary form must reproduce the above
!     copyright notice, this list of conditions and the following
!     disclaimer in the documentation and/or other materials provided
!     with the distribution.
!
!   * Neither the name of the authors nor the names of its
!     contributors may be used to endorse or promote products derived
!     from this software without specific prior written permission.
!
! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
! "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
! LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
! FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
! COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
! INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
! BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
! LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
! CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
! LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
! ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
! POSSIBILITY OF SUCH DAMAGE.
!
!> Generic Gather-scatter backend for CPUs
module gs_cpu
  use num_types
  use gs_bcknd
  use gs_ops
  implicit none
  private

  !> Gather-scatter backend for CPUs
  type, public, extends(gs_bcknd_t) :: gs_cpu_t
   contains
     procedure, pass(this) :: init => gs_cpu_init
     procedure, pass(this) :: free => gs_cpu_free
     procedure, pass(this) :: gather => gs_gather_cpu
     procedure, pass(this) :: scatter => gs_scatter_cpu
     procedure, pass(this) :: gather_many => gs_gather_many_cpu
     procedure, pass(this) :: scatter_many => gs_scatter_many_cpu
  end type gs_cpu_t
  
contains
  
  !> Dummy backend initialisation
  subroutine gs_cpu_init(this, nlocal, nshared, nlcl_blks, nshrd_blks)
    class(gs_cpu_t), intent(inout) :: this
    integer, intent(in) :: nlocal
    integer, intent(in) :: nshared
    integer, intent(in) :: nlcl_blks
    integer, intent(in) :: nshrd_blks
  end subroutine gs_cpu_init

  !> Dummy backend deallocation
  subroutine gs_cpu_free(this)
    class(gs_cpu_t), intent(inout) :: this
  end subroutine gs_cpu_free

  !> Gather kernel
  subroutine gs_gather_cpu(this, v, m, o, dg, u, n, gd, nb, b, op)
    integer, intent(inout) :: m
    integer, intent(inout) :: n
    integer, intent(inout) :: nb
    class(gs_cpu_t), intent(inout) :: this
    real(kind=rp), dimension(m), intent(inout) :: v
    integer, dimension(m), intent(inout) :: dg
    real(kind=rp), dimension(n), intent(inout) :: u
    integer, dimension(m), intent(inout) :: gd
    integer, dimension(nb), intent(inout) :: b
    integer, intent(inout) :: o
    integer :: op
    
    select case(op)
    case (GS_OP_ADD)
       call gs_gather_kernel_add(v, m, o, dg, u, n, gd, nb, b)
    case (GS_OP_MUL)
       call gs_gather_kernel_mul(v, m, o, dg, u, n, gd, nb, b)
    case (GS_OP_MIN)
       call gs_gather_kernel_min(v, m, o, dg, u, n, gd, nb, b)
    case (GS_OP_MAX)
       call gs_gather_kernel_max(v, m, o, dg, u, n, gd, nb, b)
    end select
    
  end subroutine gs_gather_cpu
 
  !> Gather kernel for addition of data
  !! \f$ v(dg(i)) = v(dg(i)) + u(gd(i)) \f$
  subroutine gs_gather_kernel_add(v, m, o, dg, u, n, gd, nb, b)
    integer, intent(in) :: m
    integer, intent(in) :: n
    integer, intent(in) :: nb
    real(kind=rp), dimension(m), intent(inout) :: v
    integer, dimension(m), intent(inout) :: dg
    real(kind=rp), dimension(n), intent(inout) :: u
    integer, dimension(m), intent(inout) :: gd
    integer, dimension(nb), intent(inout) :: b
    integer, intent(in) :: o
    integer :: i, j, k, blk_len
    real(kind=rp) :: tmp

    k = 0
    do i = 1, nb
       blk_len = b(i)
       tmp = u(gd(k + 1))
       do j = 2, blk_len
          tmp = tmp + u(gd(k + j))
       end do
       v(dg(k + 1)) = tmp
       k = k + blk_len        
    end do
    
    if (o .lt. 0) then
       do i = abs(o), m
          v(dg(i)) = u(gd(i))
       end do
    else
       do i = o, m, 2
          tmp  = u(gd(i)) + u(gd(i+1))
          v(dg(i)) = tmp
       end do
    end if
    
  end subroutine gs_gather_kernel_add

  !> Gather kernel for multiplication of data
  !! \f$ v(dg(i)) = v(dg(i)) \cdot u(gd(i)) \f$
  subroutine gs_gather_kernel_mul(v, m, o, dg, u, n, gd, nb, b)
    integer, intent(in) :: m
    integer, intent(in) :: n
    integer, intent(in) :: nb
    real(kind=rp), dimension(m), intent(inout) :: v
    integer, dimension(m), intent(inout) :: dg
    real(kind=rp), dimension(n), intent(inout) :: u
    integer, dimension(m), intent(inout) :: gd
    integer, dimension(nb), intent(inout) :: b
    integer, intent(in) :: o
    integer :: i, j, k, blk_len
    real(kind=rp) :: tmp
    
    k = 0
    do i = 1, nb
       blk_len = b(i)
       tmp = u(gd(k + 1))              
       do j = 2, blk_len
          tmp = tmp * u(gd(k + j))
       end do
       v(dg(k + 1)) = tmp
       k = k + blk_len        
    end do
       
    if (o .lt. 0) then
       do i = abs(o), m
          v(dg(i)) = u(gd(i))
       end do
    else
       do i = o, m, 2
          tmp  = u(gd(i)) * u(gd(i+1))
          v(dg(i)) = tmp
       end do
    end if
    
  end subroutine gs_gather_kernel_mul
  
  !> Gather kernel for minimum of data
  !! \f$ v(dg(i)) = \min(v(dg(i)), u(gd(i))) \f$
  subroutine gs_gather_kernel_min(v, m, o, dg, u, n, gd, nb, b)
    integer, intent(in) :: m
    integer, intent(in) :: n
    integer, intent(in) :: nb
    real(kind=rp), dimension(m), intent(inout) :: v
    integer, dimension(m), intent(inout) :: dg
    real(kind=rp), dimension(n), intent(inout) :: u
    integer, dimension(m), intent(inout) :: gd
    integer, dimension(nb), intent(inout) :: b
    integer, intent(in) :: o
    integer :: i, j, k, blk_len
    real(kind=rp) :: tmp

    k = 0
    do i = 1, nb
       blk_len = b(i)
       tmp = u(gd(k + 1))
       do j = 2, blk_len
          tmp = min(tmp, u(gd(k + j)))
       end do
       v(dg(k + 1)) = tmp
       k = k + blk_len        
    end do
       
    if (o .lt. 0) then
       do i = abs(o), m
          v(dg(i)) = u(gd(i))
       end do
    else
       do i = o, m, 2
          tmp  = min(u(gd(i)), u(gd(i+1)))
          v(dg(i)) = tmp
       end do
    end if
    
  end subroutine gs_gather_kernel_min

  !> Gather kernel for maximum of data
  !! \f$ v(dg(i)) = \max(v(dg(i)), u(gd(i))) \f$
  subroutine gs_gather_kernel_max(v, m, o, dg, u, n, gd, nb, b)
    integer, intent(in) :: m
    integer, intent(in) :: n
    integer, intent(in) :: nb
    real(kind=rp), dimension(m), intent(inout) :: v
    integer, dimension(m), intent(inout) :: dg
    real(kind=rp), dimension(n), intent(inout) :: u
    integer, dimension(m), intent(inout) :: gd
    integer, dimension(nb), intent(inout) :: b
    integer, intent(in) :: o
    integer :: i, j, k, blk_len
    real(kind=rp) :: tmp

    k = 0
    do i = 1, nb
       blk_len = b(i)
       tmp = u(gd(k + 1))
       do j = 2, blk_len
          tmp = max(tmp, u(gd(k + j)))
       end do
       v(dg(k + 1)) = tmp
       k = k + blk_len        
    end do
       
    if (o .lt. 0) then
       do i = abs(o), m
          v(dg(i)) = u(gd(i))
       end do
    else
       do i = o, m, 2
          tmp  = max(u(gd(i)), u(gd(i+1)))
          v(dg(i)) = tmp
       end do
    end if
    
  end subroutine gs_gather_kernel_max

  !> Scatter kernel  @todo Make the kernel abstract
  subroutine gs_scatter_cpu(this, v, m, dg, u, n, gd, nb, b)
    integer, intent(in) :: m
    integer, intent(in) :: n
    integer, intent(in) :: nb
    class(gs_cpu_t), intent(inout) :: this
    real(kind=rp), dimension(m), intent(inout) :: v
    integer, dimension(m), intent(inout) :: dg
    real(kind=rp), dimension(n), intent(inout) :: u
    integer, dimension(m), intent(inout) :: gd
    integer, dimension(nb), intent(inout) :: b
        
    call gs_scatter_kernel(v, m, dg, u, n, gd, nb, b)

  end subroutine gs_scatter_cpu

  !> Scatter kernel \f$ u(gd(i) = v(dg(i)) \f$
  subroutine gs_scatter_kernel(v, m, dg, u, n, gd, nb, b)
    integer, intent(in) :: m
    integer, intent(in) :: n
    integer, intent(in) :: nb
    real(kind=rp), dimension(m), intent(inout) :: v
    integer, dimension(m), intent(inout) :: dg
    real(kind=rp), dimension(n), intent(inout) :: u
    integer, dimension(m), intent(inout) :: gd
    integer, dimension(nb), intent(inout) :: b
    integer :: i, j, k, blk_len
    real(kind=rp) :: tmp
    
    k = 0
    do i = 1, nb
       blk_len = b(i)
       tmp = v(dg(k + 1))
       do j = 1, blk_len
          u(gd(k + j)) = tmp
       end do
       k = k + blk_len
    end do

    do i = k + 1, m
       u(gd(i)) = v(dg(i))
    end do

  end subroutine gs_scatter_kernel
  
  !> Gather kernel many
  subroutine gs_gather_many_cpu(this, v1, v2, v3, m, o, dg, &
                                      u1, u2, u3, n, gd, nb, b, op)
    integer, intent(inout) :: m
    integer, intent(inout) :: n
    integer, intent(inout) :: nb
    class(gs_cpu_t), intent(inout) :: this
    real(kind=rp), dimension(m), intent(inout) :: v1
    real(kind=rp), dimension(m), intent(inout) :: v2
    real(kind=rp), dimension(m), intent(inout) :: v3
    integer, dimension(m), intent(inout) :: dg
    real(kind=rp), dimension(n), intent(inout) :: u1
    real(kind=rp), dimension(n), intent(inout) :: u2
    real(kind=rp), dimension(n), intent(inout) :: u3
    integer, dimension(m), intent(inout) :: gd
    integer, dimension(nb), intent(inout) :: b
    integer, intent(inout) :: o
    integer :: op
   
    select case(op)
    case (GS_OP_ADD)
       call gs_gather_kernel_add(v1, m, o, dg, u1, n, gd, nb, b)
       call gs_gather_kernel_add(v2, m, o, dg, u2, n, gd, nb, b)
       call gs_gather_kernel_add(v3, m, o, dg, u3, n, gd, nb, b)
    case (GS_OP_MUL)
       call gs_gather_kernel_mul(v1, m, o, dg, u1, n, gd, nb, b)
       call gs_gather_kernel_mul(v2, m, o, dg, u2, n, gd, nb, b)
       call gs_gather_kernel_mul(v3, m, o, dg, u3, n, gd, nb, b)
    case (GS_OP_MIN)
       call gs_gather_kernel_min(v1, m, o, dg, u1, n, gd, nb, b)
       call gs_gather_kernel_min(v2, m, o, dg, u2, n, gd, nb, b)
       call gs_gather_kernel_min(v3, m, o, dg, u3, n, gd, nb, b)
    case (GS_OP_MAX)
       call gs_gather_kernel_max(v1, m, o, dg, u1, n, gd, nb, b)
       call gs_gather_kernel_max(v2, m, o, dg, u2, n, gd, nb, b)
       call gs_gather_kernel_max(v3, m, o, dg, u3, n, gd, nb, b)
    end select
    
  end subroutine gs_gather_many_cpu

  !> Scatter kernel many  @todo Make the kernel abstract
  subroutine gs_scatter_many_cpu(this, v1, v2, v3, m, dg, &
                                       u1, u2, u3, n, gd, nb, b)
    integer, intent(in) :: m
    integer, intent(in) :: n
    integer, intent(in) :: nb
    class(gs_cpu_t), intent(inout) :: this
    real(kind=rp), dimension(m), intent(inout) :: v1
    real(kind=rp), dimension(m), intent(inout) :: v2
    real(kind=rp), dimension(m), intent(inout) :: v3
    integer, dimension(m), intent(inout) :: dg
    real(kind=rp), dimension(n), intent(inout) :: u1
    real(kind=rp), dimension(n), intent(inout) :: u2
    real(kind=rp), dimension(n), intent(inout) :: u3
    integer, dimension(m), intent(inout) :: gd
    integer, dimension(nb), intent(inout) :: b
        
    call gs_scatter_kernel(v1, m, dg, u1, n, gd, nb, b)
    call gs_scatter_kernel(v2, m, dg, u2, n, gd, nb, b)
    call gs_scatter_kernel(v3, m, dg, u3, n, gd, nb, b)

  end subroutine gs_scatter_many_cpu

end module gs_cpu
