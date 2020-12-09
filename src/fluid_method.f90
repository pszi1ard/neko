!> Fluid formulations
module fluid_method
  use gather_scatter
  use source
  use field
  use space
  use dofmap
  use krylov
  use coefs
  use cg
  use gmres
  use mesh
  use math
  use mathops
  use operators
  implicit none
  
  !> Base type of all fluid formulations
  type, abstract :: fluid_scheme_t
     type(field_t) :: u         !< x-component of Velocity
     type(field_t) :: v         !< y-component of Velocity
     type(field_t) :: w         !< z-component of Velocity
     type(field_t) :: p         !< Pressure
     type(space_t) :: Xh        !< Function space \f$ X_h \f$
     type(dofmap_t) :: dm_Xh    !< Dofmap associated with \f$ X_h \f$
     type(gs_t) :: gs_Xh        !< Gather-scatter associated with \f$ X_h \f$
     type(coef_t) :: c_Xh       !< Coefficients associated with \f$ X_h \f$
     type(source_t) :: f_Xh     !< Source term associated with \f$ X_h \f$
     class(ksp_t), allocatable  :: ksp_vel     !< Krylov solver for velocity
     class(ksp_t), allocatable  :: ksp_prs     !< Krylov solver for pressure
     type(mesh_t), pointer :: msh => null()        !< Pointer to underlying mesh
     type(bc_list_t) :: bclst     !< Pointer to underlying mesh
   contains
     procedure, pass(this) :: fluid_scheme_init_all
     procedure, pass(this) :: fluid_scheme_init_uvw
     procedure, pass(this) :: scheme_free => fluid_scheme_free
     procedure, pass(this) :: validate => fluid_scheme_validate
     procedure(fluid_method_init), pass(this), deferred :: init
     procedure(fluid_method_free), pass(this), deferred :: free
     procedure(fluid_method_step), pass(this), deferred :: step
     generic :: scheme_init => fluid_scheme_init_all, fluid_scheme_init_uvw
  end type fluid_scheme_t

  !> Abstract interface to initialize a fluid formulation
  abstract interface
     subroutine fluid_method_init(this, msh, lx, vel, prs)
       import fluid_scheme_t
       import mesh_t
       class(fluid_scheme_t), intent(inout) :: this
       type(mesh_t), intent(inout) :: msh
       integer, intent(inout) :: lx
       character(len=80), intent(inout) :: vel
       character(len=80), intent(inout) :: prs
     end subroutine fluid_method_init
  end interface

  !> Abstract interface to dealocate a fluid formulation
  abstract interface
     subroutine fluid_method_free(this)
       import fluid_scheme_t
       class(fluid_scheme_t), intent(inout) :: this
     end subroutine fluid_method_free
  end interface
  
  !> Abstract interface to compute a time-step
  abstract interface
     subroutine fluid_method_step(this)
       import fluid_scheme_t
       class(fluid_scheme_t), intent(inout) :: this
     end subroutine fluid_method_step
  end interface

contains

  !> Initialize common data for the current scheme
  subroutine fluid_scheme_init_common(this, msh, lx)
    class(fluid_scheme_t), intent(inout) :: this
    type(mesh_t), intent(inout), target :: msh
    integer, intent(inout) :: lx

    if (msh%gdim .eq. 2) then
       call space_init(this%Xh, GLL, lx, lx)
    else
       call space_init(this%Xh, GLL, lx, lx, lx)
    end if

    this%dm_Xh = dofmap_t(msh, this%Xh)

    call gs_init(this%gs_Xh, this%dm_Xh)

    call coef_init(this%c_Xh, this%gs_Xh)

    call source_init(this%f_Xh, this%dm_Xh)

    this%msh => msh
   
  end subroutine fluid_scheme_init_common

  !> Initialize all velocity related components of the current scheme
  subroutine fluid_scheme_init_uvw(this, msh, lx, solver_vel)
    class(fluid_scheme_t), intent(inout) :: this
    type(mesh_t), intent(inout) :: msh
    integer, intent(inout) :: lx
    character(len=80), intent(inout) :: solver_vel

    call fluid_scheme_init_common(this, msh, lx)
    
    call field_init(this%u, this%dm_Xh, 'u')
    call field_init(this%v, this%dm_Xh, 'v')
    call field_init(this%w, this%dm_Xh, 'w')

    call fluid_scheme_solver_factory(this%ksp_vel, this%dm_Xh%size(), solver_vel)

  end subroutine fluid_scheme_init_uvw

  !> Initialize all components of the current scheme
  subroutine fluid_scheme_init_all(this, msh, lx, solver_vel, solver_prs)
    class(fluid_scheme_t), intent(inout) :: this
    type(mesh_t), intent(inout) :: msh
    integer, intent(inout) :: lx
    character(len=80), intent(inout) :: solver_vel
    character(len=80), intent(inout) :: solver_prs

    call fluid_scheme_init_common(this, msh, lx)
    
    call field_init(this%u, this%dm_Xh, 'u')
    call field_init(this%v, this%dm_Xh, 'v')
    call field_init(this%w, this%dm_Xh, 'w')
    call field_init(this%p, this%dm_Xh, 'p')

    call fluid_scheme_solver_factory(this%ksp_vel, this%dm_Xh%size(), solver_vel)
    call fluid_scheme_solver_factory(this%ksp_prs, this%dm_Xh%size(), solver_prs)

  end subroutine fluid_scheme_init_all

  !> Deallocate a fluid formulation
  subroutine fluid_scheme_free(this)
    class(fluid_scheme_t), intent(inout) :: this

    call field_free(this%u)
    call field_free(this%v)
    call field_free(this%w)
    call field_free(this%p)

    call space_free(this%Xh)

    if (allocated(this%ksp_vel)) then
       call this%ksp_vel%free()
       deallocate(this%ksp_vel)
    end if

    if (allocated(this%ksp_prs)) then
       call this%ksp_prs%free()
       deallocate(this%ksp_prs)
    end if

    call gs_free(this%gs_Xh)

    call coef_free(this%c_Xh)

    call source_free(this%f_Xh)
    
  end subroutine fluid_scheme_free

  !> Validate that all fields, solvers etc necessary for
  !! performing time-stepping are defined
  subroutine fluid_scheme_validate(this)
    class(fluid_scheme_t), intent(inout) :: this

    if ( (.not. allocated(this%u%x)) .or. &
         (.not. allocated(this%v%x)) .or. &
         (.not. allocated(this%w%x)) .or. &
         (.not. allocated(this%p%x))) then
       call neko_error('Fields are not allocated')
    end if

    if (.not. allocated(this%ksp_vel)) then
       call neko_error('No Krylov solver for velocity defined')
    end if
    
    if (.not. allocated(this%ksp_prs)) then
       call neko_error('No Krylov solver for pressure defined')
    end if

    if (.not. associated(this%f_Xh%eval)) then
       call neko_error('No source term defined')
    end if

  end subroutine fluid_scheme_validate

  !> Initialize a linear solver
  !! @note Currently only supporting Krylov solvers
  subroutine fluid_scheme_solver_factory(ksp, n, solver)
    class(ksp_t), allocatable, intent(inout) :: ksp
    integer, intent(in), value :: n
    character(len=80), intent(inout) :: solver

    if (trim(solver) .eq. 'cg') then
       allocate(cg_t::ksp)
    else if (trim(solver) .eq. 'gmres') then
       allocate(gmres_t::ksp)
    else
       call neko_error('Unknown linear solver')
    end if

    select type(kp => ksp)
    type is(cg_t)
       call kp%init(n)
    type is(gmres_t)
       call kp%init(n)
    end select
    
  end subroutine fluid_scheme_solver_factory
  
end module fluid_method
