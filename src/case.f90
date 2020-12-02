!> Defines a simulation case
module case
  use num_types
  use fluid_schemes
  use parameters
  use mpi_types
  use file
  use utils
  use mesh
  use comm
  implicit none

  type :: case_t
     type(mesh_t) :: msh
     type(param_t) :: params
     class(fluid_scheme_t), allocatable :: fluid
  end type case_t

contains

  !> Initialize a case from an input file @a case_file
  subroutine case_init(C, case_file)
    type(case_t), intent(inout) :: C
    character(len=*), intent(in) :: case_file

    ! Namelist for case description
    character(len=NEKO_FNAME_LEN) :: mesh_file = ''
    character(len=NEKO_FNAME_LEN) :: fluid_scheme  = ''
    character(len=80) :: solver_velocity = ''
    character(len=80) :: solver_pressure = ''
    integer :: lx = 0
    type(param_io_t) :: params
    namelist /NEKO_CASE/ mesh_file, fluid_scheme, lx, params, &
         solver_velocity, solver_pressure


    integer :: ierr
    type(file_t) :: msh_file
    integer, parameter :: nbytes = 2*NEKO_FNAME_LEN + 160 + 8
    character buffer(nbytes)
    integer :: pack_index
    
    if (pe_rank .eq. 0) then
       open(10, file=trim(case_file))
       read(10, nml=NEKO_CASE)
       close(10)

       pack_index = 1
       call MPI_Pack(mesh_file, NEKO_FNAME_LEN, MPI_CHARACTER, &
            buffer, nbytes, pack_index, NEKO_COMM, ierr)
       call MPI_Pack(fluid_scheme, NEKO_FNAME_LEN, MPI_CHARACTER, &
            buffer, nbytes, pack_index, NEKO_COMM, ierr)
       call MPI_Pack(solver_velocity, 80, MPI_CHARACTER, &
            buffer, nbytes, pack_index, NEKO_COMM, ierr)
       call MPI_Pack(solver_pressure, 80, MPI_CHARACTER, &
            buffer, nbytes, pack_index, NEKO_COMM, ierr)
       call MPI_Pack(lx, 1, MPI_INTEGER, &
            buffer, nbytes, pack_index, NEKO_COMM, ierr)
       call MPI_Bcast(buffer, nbytes, MPI_PACKED, 0, NEKO_COMM, ierr)
       call MPI_Bcast(params%p, 1, MPI_NEKO_PARAMS, 0, NEKO_COMM, ierr)
    else
       call MPI_Bcast(buffer, nbytes, MPI_PACKED, 0, NEKO_COMM, ierr)
       pack_index = 1

       call MPI_Unpack(buffer, nbytes, pack_index, &
            mesh_file, NEKO_FNAME_LEN, MPI_CHARACTER, NEKO_COMM, ierr)
       call MPI_Unpack(buffer, nbytes, pack_index, &
            fluid_scheme, NEKO_FNAME_LEN, MPI_CHARACTER, NEKO_COMM, ierr)
       call MPI_Unpack(buffer, nbytes, pack_index, &
            solver_velocity, 80, MPI_CHARACTER, NEKO_COMM, ierr)
       call MPI_Unpack(buffer, nbytes, pack_index, &
            solver_pressure, 80, MPI_CHARACTER, NEKO_COMM, ierr)
       call MPI_Unpack(buffer, nbytes, pack_index, &
            lx, 1, MPI_INTEGER, NEKO_COMM, ierr)
       call MPI_Bcast(params%p, 1, MPI_NEKO_PARAMS, 0, NEKO_COMM, ierr)
    end if

    msh_file = file_t(trim(mesh_file))
    call msh_file%read(C%msh)
    call mesh_generate_conn(C%msh) 

    C%params = params%p

    if (trim(fluid_scheme) .eq. 'plan1') then
       allocate(fluid_plan1_t::C%fluid)
    else if (trim(fluid_scheme) .eq. 'plan4') then
       allocate(fluid_plan4_t::C%fluid)
    else
       call neko_error('Invalid fluid scheme')
    end if

    call C%fluid%init(C%msh, lx, solver_velocity, solver_pressure)
    
  end subroutine case_init

  !> Deallocate a case 
  subroutine case_free(C)
    type(case_t), intent(inout) :: C

    if (allocated(C%fluid)) then
       call C%fluid%free()
       deallocate(C%fluid)
    end if

    call mesh_free(C%msh)
    
  end subroutine case_free
  
end module case
