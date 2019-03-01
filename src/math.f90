module math
  use num_types
  implicit none

  real(kind=dp), parameter :: NEKO_EPS = epsilon(1d0)

contains

  !> Return absolute comparison \f$ | x - y | < \epsilon \f$
  pure function abscmp(x, y)
    real(kind=dp), intent(in) :: x
    real(kind=dp), intent(in) :: y
    logical :: abscmp 

    abscmp = abs(x - y) .lt. NEKO_EPS

  end function abscmp

  !> Zero a real vector
  subroutine rzero(a, n)
    real(kind=dp), dimension(n), intent(inout) :: a
    integer, intent(in) :: n
    integer :: i
    
    do i = 1, n
       a(i) = 0d0
    end do
  end subroutine rzero

  !> Zero an integer vector
  subroutine izero(a, n)
    integer, dimension(n), intent(inout) :: a
    integer, intent(in) :: n
    integer :: i
    
    do i = 1, n
       a(i) = 0d0
    end do
  end subroutine izero

  !> Set all elements to one
  subroutine rone(a, n)
    real(kind=dp), dimension(n), intent(inout) :: a
    integer, intent(in) :: n
    integer :: i
    
    do i = 1, n
       a(i) = 1d0
    end do
  end subroutine rone

  !> Copy a vector \f$ a = b \f$
  subroutine copy(a, b, n)
    real(kind=dp), dimension(n), intent(in) :: b
    real(kind=dp), dimension(n), intent(inout) :: a
    integer, intent(in) :: n
    integer :: i

    do i = 1, n
       a(i) = b(i)
    end do

  end subroutine copy
  


  !> Compute a cross product \f$ u = v \times w \f$
  !! @detailed assuming vector components \f$ u = (u_1, u_2, u_3) \f$ etc.
  subroutine vcross(u1, u2, u3,  v1, v2, v3, w1, w2, w3, n)
    real(kind=dp), dimension(n), intent(in) :: v1, v2, v3
    real(kind=dp), dimension(n), intent(in) :: w1, w2, w3
    real(kind=dp), dimension(n), intent(out) :: u1, u2, u3
    integer, intent(in) :: n
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
    real(kind=dp), dimension(n), intent(in) :: u1, u2
    real(kind=dp), dimension(n), intent(in) :: v1, v2
    real(kind=dp), dimension(n), intent(out) :: dot
    integer, intent(in) :: n
    integer :: i
    do i = 1, n 
       dot(i) = u1(i)*v1(i) + u2(i)*v2(i)
    end do

  end subroutine vdot2

  !> Compute a dot product \f$ dot = u \cdot v \f$ (3-d version) 
  !! assuming vector components \f$ u = (u_1, u_2, u_3) \f$ etc.
  subroutine vdot3(dot, u1, u2, u3, v1, v2, v3, n)
    real(kind=dp), dimension(n), intent(in) :: u1, u2, u3
    real(kind=dp), dimension(n), intent(in) :: v1, v2, v3
    real(kind=dp), dimension(n), intent(out) :: dot
    integer, intent(in) :: n
    integer :: i

    do i = 1, n 
       dot(i) = u1(i)*v1(i) + u2(i)*v2(i) + u3(i)*v3(i)
    end do

  end subroutine vdot3

  !> Vector addition \f$ a = a + b \f$
  subroutine add2(a, b, n)
    real(kind=dp), dimension(n), intent(inout) :: a
    real(kind=dp), dimension(n), intent(in) :: b
    integer, intent(in) :: n
    integer :: i

    do i = 1, n
       a(i) = a(i) + b(i)
    end do

  end subroutine add2

  !> Vector addition \f$ a = b + c \f$
  subroutine add3(a, b, c, n)
    real(kind=dp), dimension(n), intent(inout) :: c
    real(kind=dp), dimension(n), intent(inout) :: b
    real(kind=dp), dimension(n), intent(out) :: a
    integer, intent(in) :: n
    integer :: i

    do i = 1, n
       a(i) = b(i) + c(i)
    end do

  end subroutine add3

  !> Vector addition \f$ a = b + c + d\f$
  subroutine add4(a, b, c, d, n)
    real(kind=dp), dimension(n), intent(inout) :: d
    real(kind=dp), dimension(n), intent(inout) :: c
    real(kind=dp), dimension(n), intent(inout) :: b
    real(kind=dp), dimension(n), intent(out) :: a
    integer, intent(in) :: n
    integer :: i

    do i = 1, n
       a(i) = b(i) + c(i) + d(i)
    end do

  end subroutine add4

  !> Vector addition with scalar multiplication \f$ a = c_1 a + b \f$
  !! (multiplication on first argument)
  subroutine add2s1(a, b, c1, n)
    real(kind=dp), dimension(n), intent(inout) :: a
    real(kind=dp), dimension(n), intent(inout) :: b
    real(kind=dp), intent(in) :: c1
    integer, intent(in) :: n
    integer :: i

    do i = 1, n
       a(i) = c1 * a(i) + b(i)
    end do
    
  end subroutine add2s1

  !> Vector addition with scalar multiplication  \f$ a = a + c_1 b \f$
  !! (multiplication on second argument)
  subroutine add2s2(a, b, c1, n)
    real(kind=dp), dimension(n), intent(inout) :: a
    real(kind=dp), dimension(n), intent(inout) :: b
    real(kind=dp), intent(in) :: c1
    integer, intent(in) :: n
    integer :: i

    do i = 1, n
       a(i) =a(i) + c1 * b(i)
    end do
    
  end subroutine add2s2

  !> Weighted inner product \f$ a^T b c \f$
  function glsc3(a, b, c, n)
    real(kind=dp), dimension(n), intent(in) :: a
    real(kind=dp), dimension(n), intent(in) :: b
    real(kind=dp), dimension(n), intent(in) :: c
    integer, intent(in) :: n
    real(kind=dp) :: glsc3
    integer :: i

    glsc3 = 0d0
    do i = 1, n
       glsc3 = glsc3 + a(i) * b(i) * c(i)
    end do
    !> @todo add global reduction
  end function glsc3
  
end module math
