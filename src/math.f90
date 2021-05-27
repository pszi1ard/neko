module math
  use num_types
  use comm
  implicit none

  !> Machine epsilon \f$ \epsilon \f$
  real(kind=rp), parameter :: NEKO_EPS = epsilon(1d0)

  !> \f$ ln(2) \f$
  real(kind=rp), parameter :: NEKO_M_LN2 = 0.693147180559945d0

  interface abscmp
     module procedure sabscmp, dabscmp, qabscmp
  end interface abscmp

contains

  !> Return single precision absolute comparison \f$ | x - y | < \epsilon \f$
  pure function sabscmp(x, y)
    real(kind=sp), intent(in) :: x
    real(kind=sp), intent(in) :: y
    logical :: sabscmp 

    sabscmp = abs(x - y) .lt. NEKO_EPS

  end function sabscmp

  !> Return double precision absolute comparison \f$ | x - y | < \epsilon \f$
  pure function dabscmp(x, y)
    real(kind=dp), intent(in) :: x
    real(kind=dp), intent(in) :: y
    logical :: dabscmp 

    dabscmp = abs(x - y) .lt. NEKO_EPS
    
  end function dabscmp

  !> Return double precision absolute comparison \f$ | x - y | < \epsilon \f$
  pure function qabscmp(x, y)
    real(kind=qp), intent(in) :: x
    real(kind=qp), intent(in) :: y
    logical :: qabscmp 

    qabscmp = abs(x - y) .lt. NEKO_EPS

  end function qabscmp

  !> Zero a real vector
  subroutine rzero(a, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: a
    integer :: i
    
    do i = 1, n
       a(i) = 0d0
    end do
  end subroutine rzero

  !> Zero an integer vector
  subroutine izero(a, n)
    integer, intent(in) :: n
    integer, dimension(n), intent(inout) :: a
    integer :: i
    
    do i = 1, n
       a(i) = 0d0
    end do
  end subroutine izero

 !> Sets row e to 0 in matrix a
  subroutine row_zero(a,m,n,e)
    integer, intent(in) :: m,n,e
    real(kind=rp), intent(inout) :: a(m,n)
    integer :: j
    do j=1,n
       a(e,j)=0.
    enddo
  end subroutine row_zero

  !> Set all elements to one
  subroutine rone(a, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: a
    integer :: i
    
    do i = 1, n
       a(i) = 1d0
    end do
  end subroutine rone

  !> Copy a vector \f$ a = b \f$
  subroutine copy(a, b, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(inout) :: a
    integer :: i

    do i = 1, n
       a(i) = b(i)
    end do

  end subroutine copy
  
  !> Multiplication by constant c \f$ a = c \cdot a \f$
  subroutine cmult(a, c, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), intent(in) :: c
    integer :: i

    do i = 1, n
       a(i) = c * a(i)
    end do
  end subroutine cmult
  
  !> Add a scalar to vector \f$ a = \sum a_i + s \f$
  subroutine cadd(a, s, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), intent(in) :: s
    integer :: i
    
    do i = 1, n
       a(i) = a(i) + s
    end do
  end subroutine cadd

  !>Sum a vector of length n 
  function glsum(a, n) 
    integer, intent(in) :: n
    real(kind=rp), dimension(n) :: a
    real(kind=rp) :: tmp, glsum
    integer :: i, ierr
    tmp = 0d0
    do i = 1, n
       tmp = tmp + a(i)
    end do
    call MPI_Allreduce(tmp, glsum, 1, &
         MPI_REAL_PRECISION, sum_real, NEKO_COMM, ierr)
    
  end function glsum
  
  !>Max of a vector of length n 
  function glmax(a, n) 
    integer, intent(in) :: n
    real(kind=rp), dimension(n) :: a
    real(kind=rp) :: tmp, glmax
    integer :: i, ierr
    tmp = a(1)
    do i = 2, n
       tmp =  max(tmp,a(i))
    end do
    call MPI_Allreduce(tmp, glmax, 1, &
         MPI_REAL_PRECISION, MPI_MAX, NEKO_COMM, ierr)
  end function glmax
  
  !>Min of a vector of length n 
  function glmin(a, n) 
    integer, intent(in) :: n
    real(kind=rp), dimension(n) :: a
    real(kind=rp) :: tmp, glmin
    integer :: i, ierr
    tmp = a(1)
    do i = 2, n
       tmp =  min(tmp,a(i))
    end do
    call MPI_Allreduce(tmp, glmin, 1, &
         MPI_REAL_PRECISION, MPI_MIN, NEKO_COMM, ierr)
  end function glmin



  !> Change sign of vector \f$ a = -a \f$
  subroutine chsign(a, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: a
    integer :: i

    do i = 1, n
       a(i) = -a(i)
    end do
    
  end subroutine chsign
  
  !> Maximum value of a vector of length @a n
  function vlmax(vec,n) result(tmax)
    integer :: n, i
    real(kind=rp), intent(in) :: vec(n)
    real(kind=rp) :: tmax
    tmax =-99d20
    do i=1,n
       tmax = max(tmax,vec(i))
    enddo
  end function vlmax
  
  !> Invert a vector \f$ a = 1 / a \f$
  subroutine invcol1(a, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: a
    integer :: i

    do i = 1, n
       a(i) = 1d0 / a(i)
    end do
    
  end subroutine invcol1
 
  !> Invert a vector \f$ a = b / a \f$
  subroutine invcol3(a, b, c, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b,c
    integer :: i

    do i = 1, n
       a(i) = b(i) / c(i)
    end do
    
  end subroutine invcol3
   
  !> Compute inverted vector \f$ a = 1 / b \f$
  subroutine invers2(a, b, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    integer :: i

    do i = 1, n
       a(i) = 1d0 / b(i)
    end do
    
  end subroutine invers2

  !> Compute a cross product \f$ u = v \times w \f$
  !! assuming vector components \f$ u = (u_1, u_2, u_3) \f$ etc.
  subroutine vcross(u1, u2, u3,  v1, v2, v3, w1, w2, w3, n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(in) :: v1, v2, v3
    real(kind=rp), dimension(n), intent(in) :: w1, w2, w3
    real(kind=rp), dimension(n), intent(out) :: u1, u2, u3
    integer :: i

    do i = 1, n
       u1(i) = v2(i)*w3(i) - v3(i)*w2(i)
       u2(i) = v3(i)*w1(i) - v1(i)*w3(i)
       u3(i) = v1(i)*w2(i) - v2(i)*w1(i)
    end do

  end subroutine vcross

  !> Compute a dot product \f$ dot = u \cdot v \f$ (2-d version) 
  !! assuming vector components \f$ u = (u_1, u_2, u_3) \f$ etc.
  subroutine vdot2(dot, u1, u2, v1, v2, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(in) :: u1, u2
    real(kind=rp), dimension(n), intent(in) :: v1, v2
    real(kind=rp), dimension(n), intent(out) :: dot
    integer :: i
    do i = 1, n 
       dot(i) = u1(i)*v1(i) + u2(i)*v2(i)
    end do

  end subroutine vdot2

  !> Compute a dot product \f$ dot = u \cdot v \f$ (3-d version) 
  !! assuming vector components \f$ u = (u_1, u_2, u_3) \f$ etc.
  subroutine vdot3(dot, u1, u2, u3, v1, v2, v3, n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(in) :: u1, u2, u3
    real(kind=rp), dimension(n), intent(in) :: v1, v2, v3
    real(kind=rp), dimension(n), intent(out) :: dot
    integer :: i

    do i = 1, n 
       dot(i) = u1(i)*v1(i) + u2(i)*v2(i) + u3(i)*v3(i)
    end do

  end subroutine vdot3

  !> Compute multiplication sum \f$ dot = u \cdot v \cdot w \f$  
  function vlsc3(u, v, w, n) result(s)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(in) :: u, v, w
    real(kind=rp) :: s
    integer :: i

    s = 0d0
    do i = 1, n 
      s = s + u(i)*v(i)*w(i)
    end do

  end function vlsc3
  
  !> Compute multiplication sum \f$ dot = u \cdot v \cdot w \f$  
  function vlsc2(u, v, n) result(s)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(in) :: u, v
    real(kind=rp) :: s
    integer :: i

    s = 0d0
    do i = 1, n 
      s = s + u(i)*v(i)
    end do

  end function vlsc2

  !> Vector addition \f$ a = a + b \f$
  subroutine add2(a, b, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    integer :: i

    do i = 1, n
       a(i) = a(i) + b(i)
    end do

  end subroutine add2

  !> Vector addition \f$ a = b + c \f$
  subroutine add3(a, b, c, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: c
    real(kind=rp), dimension(n), intent(inout) :: b
    real(kind=rp), dimension(n), intent(out) :: a
    integer :: i

    do i = 1, n
       a(i) = b(i) + c(i)
    end do

  end subroutine add3

  !> Vector addition \f$ a = b + c + d\f$
  subroutine add4(a, b, c, d, n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: d
    real(kind=rp), dimension(n), intent(inout) :: c
    real(kind=rp), dimension(n), intent(inout) :: b
    real(kind=rp), dimension(n), intent(out) :: a
    integer :: i

    do i = 1, n
       a(i) = b(i) + c(i) + d(i)
    end do

  end subroutine add4

  !> Vector substraction \f$ a = a - b \f$
  subroutine sub2(a, b, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(inout) :: b
    integer :: i

    do i = 1, n
       a(i) = a(i) - b(i)
    end do
    
  end subroutine sub2

  !> Vector subtraction \f$ a = b - c \f$
  subroutine sub3(a, b, c, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: c
    real(kind=rp), dimension(n), intent(inout) :: b
    real(kind=rp), dimension(n), intent(out) :: a
    integer :: i

    do i = 1, n
       a(i) = b(i) - c(i)
    end do

  end subroutine sub3


  !> Vector addition with scalar multiplication \f$ a = c_1 a + b \f$
  !! (multiplication on first argument)
  subroutine add2s1(a, b, c1, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(inout) :: b
    real(kind=rp), intent(in) :: c1
    integer :: i

    do i = 1, n
       a(i) = c1 * a(i) + b(i)
    end do
    
  end subroutine add2s1

  !> Vector addition with scalar multiplication  \f$ a = a + c_1 b \f$
  !! (multiplication on second argument)
  subroutine add2s2(a, b, c1, n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(inout) :: b
    real(kind=rp), intent(in) :: c1
    integer :: i

    do i = 1, n
       a(i) = a(i) + c1 * b(i)
    end do
    
  end subroutine add2s2
  
  !> Multiplication by constant c \f$ a = c \cdot b \f$
  subroutine cmult2(a, b, c, n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), intent(in) :: c
    integer :: i

    do i = 1, n
       a(i) = c * b(i)
    end do
    
  end subroutine cmult2

  !> Vector division \f$ a = a / b \f$
  subroutine invcol2(a, b, n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    integer :: i

    do i = 1, n
       a(i) = a(i) /b(i)
    end do
    
  end subroutine invcol2


  !> Vector multiplication \f$ a = a \cdot b \f$
  subroutine col2(a, b, n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    integer :: i

    do i = 1, n
       a(i) = a(i) * b(i)
    end do
    
  end subroutine col2

  !> Vector multiplication with 3 vectors \f$ a = a \cdot b \cdot c \f$
  subroutine col3(a, b, c, n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(in) :: c
    integer :: i

    do i = 1, n
       a(i) =  b(i) * c(i)
    end do
    
  end subroutine col3

  !> Returns \f$ a = a - b*c \f$
  subroutine subcol3(a,b,c,n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(in) :: c
    integer :: i

    do i = 1,n
       a(i) = a(i) - b(i) * c(i) 
    end do

  end subroutine subcol3

  !> Returns \f$ a = c1 * b + c2 * c \f$
  subroutine add3s2(a,b,c,c1,c2,n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(in) :: c
    real(kind=rp), intent(in) :: c1, c2
    integer :: i

    do i = 1,n
       a(i) = c1 * b(i) + c2 * c(i) 
    end do

  end subroutine add3s2


  !> Returns \f$ a = a - b*c*d \f$
  subroutine subcol4(a,b,c,d,n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(in) :: c
    real(kind=rp), dimension(n), intent(in) :: d
    integer :: i

    do i = 1,n
       a(i) = a(i) - b(i) * c(i) * d(i)
    end do

  end subroutine subcol4
  
  !> Returns \f$ a = a + b*c \f$
  subroutine addcol3(a,b,c,n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(in) :: c
    integer :: i

    do i = 1,n
       a(i) = a(i) + b(i) * c(i) 
    end do

  end subroutine addcol3

  !> Returns \f$ a = a + b*c*d \f$
  subroutine addcol4(a,b,c,d,n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(in) :: c
    real(kind=rp), dimension(n), intent(in) :: d
    integer :: i

    do i = 1,n
       a(i) = a(i) + b(i) * c(i) * d(i)
    end do

  end subroutine addcol4

  !> Returns \f$ a = b \dot c - d \cdot e \f$
  subroutine ascol5(a,b,c,d,e,n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(in) :: c
    real(kind=rp), dimension(n), intent(in) :: d
    real(kind=rp), dimension(n), intent(in) :: e
    integer :: i

    do i = 1,n
       a(i) = b(i)*c(i)-d(i)*e(i)
    end do

  end subroutine ascol5

  !> Returns \f$ a = b \dot c1 ( a - c2 \cdot c )\f$
  subroutine p_update(a,b,c,c1,c2,n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(in) :: c
    real(kind=rp), intent(in) :: c1, c2
    integer :: i

    do i = 1,n
       a(i) = b(i) + c1*(a(i)-c2*c(i))
    end do

  end subroutine p_update

  !> Returns \f$ a = b \dot c1 ( a - c2 \cdot c )\f$
  subroutine x_update(a,b,c,c1,c2,n)
    integer, intent(in) :: n    
    real(kind=rp), dimension(n), intent(inout) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(in) :: c
    real(kind=rp), intent(in) :: c1, c2
    integer :: i

    do i = 1,n
       a(i) = a(i) + c1*b(i)+c2*c(i)
    end do

  end subroutine x_update

  !> Weighted inner product \f$ a^T b c \f$
  function glsc2(a, b,  n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(in) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp) :: glsc2, tmp
    integer :: i, ierr

    tmp = 0d0
    do i = 1, n
       tmp = tmp + a(i) * b(i) 
    end do
    
    call MPI_Allreduce(tmp, glsc2, 1, &
         MPI_REAL_PRECISION, sum_real, NEKO_COMM, ierr)

  end function glsc2
  
  !> Weighted inner product \f$ a^T b c \f$
  function glsc3(a, b, c, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(in) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(in) :: c
    real(kind=rp) :: glsc3, tmp
    integer :: i, ierr

    tmp = 0d0
    do i = 1, n
       tmp = tmp + a(i) * b(i) * c(i)
    end do
    
    call MPI_Allreduce(tmp, glsc3, 1, &
         MPI_REAL_PRECISION, sum_real, NEKO_COMM, ierr)

  end function glsc3
  function glsc4(a, b, c,d, n)
    integer, intent(in) :: n
    real(kind=rp), dimension(n), intent(in) :: a
    real(kind=rp), dimension(n), intent(in) :: b
    real(kind=rp), dimension(n), intent(in) :: c
    real(kind=rp), dimension(n), intent(in) :: d
    real(kind=rp) :: glsc4, tmp
    integer :: i, ierr

    tmp = 0d0
    do i = 1, n
       tmp = tmp + a(i) * b(i) * c(i) * d(i)
    end do
    
    call MPI_Allreduce(tmp, glsc4, 1, &
         MPI_REAL_PRECISION, sum_real, NEKO_COMM, ierr)

  end function glsc4
  
end module math
