module fld_file_data
  use field
  use vector
  use math
  implicit none

  type, public :: fld_file_data_t
     type(vector_t) :: x
     type(vector_t) :: y
     type(vector_t) :: z
     type(vector_t) :: u
     type(vector_t) :: v
     type(vector_t) :: w
     type(vector_t) :: p
     type(vector_t) :: t
     integer, allocatable :: idx(:)
     type(vector_t), allocatable :: s(:)
     integer :: gdim
     integer :: n_scalars = 0
     real(kind=rp) :: time = 0.0
     integer :: glb_nelv = 0 
     integer :: nelv = 0 
     integer :: offset_el = 0
     integer :: lx = 0
     integer :: ly = 0
     integer :: lz = 0
     integer :: t_counter = 0
     ! meta file information (if any)
     integer :: meta_nsamples = 0
     integer :: meta_start_counter = 0
     character(len=1024) :: fld_series_fname

   contains
     procedure, pass(this) :: init => fld_file_data_init
     procedure, pass(this) :: free => fld_file_data_free
     procedure, pass(this) :: scale => fld_file_data_scale
     procedure, pass(this) :: add => fld_file_data_add
  end type fld_file_data_t

contains
  !> Initialise a fld_file_data object with nelv elements with a offset_nel
  subroutine fld_file_data_init(this, nelv, offset_el)
    class(fld_file_data_t), intent(inout) :: this
    integer, intent(in), optional :: nelv, offset_el
    call this%free()
    if (present(nelv)) this%nelv = nelv
    if (present(offset_el)) this%offset_el = offset_el
    
  end subroutine fld_file_data_init

  !> Scale the values stored in this fld_file_data
  subroutine fld_file_data_scale(this, c)
    class(fld_file_data_t), intent(inout) :: this
    real(kind=rp), intent(in) :: c
    integer :: i

    if(this%u%n .gt. 0) call cmult(this%u%x,c,this%u%n)
    if(this%v%n .gt. 0) call cmult(this%v%x,c,this%v%n)
    if(this%w%n .gt. 0) call cmult(this%w%x,c,this%w%n)
    if(this%p%n .gt. 0) call cmult(this%p%x,c,this%p%n)
    if(this%t%n .gt. 0) call cmult(this%t%x,c,this%t%n)

    do i = 1, this%n_scalars
       if(this%s(i)%n .gt. 0) call cmult(this%s(i)%x,c,this%s(i)%n)
    end do

  end subroutine fld_file_data_scale

  !> Add the values in another fld file to this
  subroutine fld_file_data_add(this, fld_data_add)
    class(fld_file_data_t), intent(inout) :: this
    class(fld_file_data_t), intent(in) :: fld_data_add
    integer :: i

    if(this%u%n .gt. 0) call add2(this%u%x,fld_data_add%u%x,this%u%n)
    if(this%v%n .gt. 0) call add2(this%v%x,fld_data_add%v%x,this%v%n)
    if(this%w%n .gt. 0) call add2(this%w%x,fld_data_add%w%x,this%w%n)
    if(this%p%n .gt. 0) call add2(this%p%x,fld_data_add%p%x,this%p%n)
    if(this%t%n .gt. 0) call add2(this%t%x,fld_data_add%t%x,this%t%n)

    do i = 1, this%n_scalars
       if(this%s(i)%n .gt. 0) call add2(this%s(i)%x,fld_data_add%s(i)%x,this%s(i)%n)
    end do
  end subroutine fld_file_data_add

  !> Deallocate fld file data type
  subroutine fld_file_data_free(this)
    class(fld_file_data_t), intent(inout) :: this
    integer :: i
    call this%x%free()
    call this%y%free()
    call this%z%free()
    call this%u%free()
    call this%v%free()
    call this%w%free()
    call this%p%free()
    call this%t%free()
    if (allocated(this%s)) then
        do i = 1, this%n_scalars
           call this%s(i)%free()
        end do
    end if
    this%n_scalars = 0
    this%time = 0.0
    this%glb_nelv = 0 
    this%nelv = 0 
    this%offset_el = 0
    this%lx = 0
    this%ly = 0
    this%lz = 0
    this%t_counter = 0
    this%meta_nsamples = 0
    this%meta_start_counter = 0
  end subroutine fld_file_data_free

end module fld_file_data