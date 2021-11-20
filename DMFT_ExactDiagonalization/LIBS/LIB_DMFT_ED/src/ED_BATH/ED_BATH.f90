MODULE ED_BATH
  USE SF_CONSTANTS, only: zero
  USE SF_IOTOOLS, only:free_unit,reg,file_length,txtfy
  USE SF_LINALG, only: eye,inv
  USE SF_ARRAYS, only:linspace
  USE SF_MISC, only: assert_shape
  USE ED_INPUT_VARS
  USE ED_VARS_GLOBAL
  USE ED_AUX_FUNX
  implicit none

  private

  !##################################################################
  !
  !     USER BATH ROUTINES:
  !
  !##################################################################
  !Interface for user bath I/O operations: get,set,copy
  interface get_bath_dimension
     module procedure ::  get_bath_dimension_direct
     module procedure ::  get_bath_dimension_symmetries
  end interface get_bath_dimension

  interface set_Hreplica
     module procedure init_Hreplica_direct_so
     module procedure init_Hreplica_direct_nn
     module procedure init_Hreplica_symmetries_site
     module procedure init_Hreplica_symmetries_lattice
  end interface set_Hreplica

  !explicit symmetries:
  interface break_symmetry_bath
     module procedure break_symmetry_bath_site
     module procedure break_symmetry_bath_lattice
  end interface break_symmetry_bath

  interface spin_symmetrize_bath
     module procedure spin_symmetrize_bath_site
     module procedure spin_symmetrize_bath_lattice
  end interface spin_symmetrize_bath

  interface orb_symmetrize_bath
     module procedure orb_symmetrize_bath_site
     module procedure orb_symmetrize_bath_lattice
  end interface orb_symmetrize_bath

  interface orb_equality_bath
     module procedure orb_equality_bath_site
     module procedure orb_equality_bath_lattice
  end interface orb_equality_bath

  interface ph_symmetrize_bath
     module procedure ph_symmetrize_bath_site
     module procedure ph_symmetrize_bath_lattice
  end interface ph_symmetrize_bath

  interface ph_trans_bath
     module procedure ph_trans_bath_site
     module procedure ph_trans_bath_lattice
  end interface ph_trans_bath

  interface enforce_normal_bath
     module procedure enforce_normal_bath_site
     module procedure enforce_normal_bath_lattice
  end interface enforce_normal_bath

  !Aux:
  interface get_Whyb_matrix
     module procedure get_Whyb_matrix_1orb
     module procedure get_Whyb_matrix_Aorb
     module procedure get_Whyb_matrix_dmft_bath
  end interface get_Whyb_matrix

  interface is_identity
     module procedure ::  is_identity_so
     module procedure ::  is_identity_nn
  end interface is_identity

  interface is_diagonal
     module procedure ::  is_diagonal_so
     module procedure ::  is_diagonal_nn
  end interface is_diagonal






  !##################################################################
  !
  !     USER BATH ROUTINES:
  !
  !##################################################################
  public :: get_bath_dimension
  public :: check_bath_dimension
  !
  public :: get_bath_component_dimension
  public :: get_bath_component
  public :: set_bath_component
  public :: copy_bath_component
  !

  public :: break_symmetry_bath              
  public :: spin_symmetrize_bath
  public :: orb_symmetrize_bath
  public :: orb_equality_bath
  public :: ph_symmetrize_bath
  public :: ph_trans_bath
  public :: enforce_normal_bath
  public :: get_Whyb_matrix
  public :: impose_equal_lambda
  public :: impose_bath_offset
  !
  public :: set_Hreplica


  !##################################################################
  !
  !     DMFT BATH ROUTINES:
  !
  !##################################################################
  public :: allocate_dmft_bath               !INTERNAL (for effective_bath)
  public :: deallocate_dmft_bath             !INTERNAL (for effective_bath)
  public :: init_dmft_bath                   !INTERNAL (for effective_bath)
  public :: write_dmft_bath                  !INTERNAL (for effective_bath)
  public :: save_dmft_bath                   !INTERNAL (for effective_bath)
  public :: set_dmft_bath                    !INTERNAL (for effective_bath)
  public :: get_dmft_bath                    !INTERNAL (for effective_bath)
  !
  public :: hreplica_build                   !INTERNAL (for effective_bath)
  public :: hreplica_mask                    !INTERNAL (for effective_bath)
  public :: hreplica_site                    !INTERNAL (for effective_bath)


  integer :: ibath,ilat,iorb



contains


  !+-------------------------------------------------------------------+
  !PURPOSE  : Inquire the correct bath size to allocate the 
  ! the bath array in the calling program.
  !+-------------------------------------------------------------------+
  function get_bath_dimension_direct(Hloc_nn) result(bath_size)
    complex(8),optional,intent(in) :: Hloc_nn(:,:,:,:)
    integer                        :: bath_size,ndx,ispin,iorb,jspin,jorb,io,jo,Maxspin
    complex(8),allocatable         :: Hloc(:,:,:,:)
    !
    select case(bath_type)
       !
    case default
       select case(ed_mode)
       case default
          bath_size = Norb*Nbath + Norb*Nbath
          !( e [Nspin][Norb][Nbath] + v [Nspin][Norb][Nbath] )
       case ("superc")
          bath_size = Norb*Nbath + Norb*Nbath + Norb*Nbath
          !( e [Nspin][Norb][Nbath] + d [Nspin][Norb][Nbath] + v [Nspin][Norb][Nbath] )
       case ("nonsu2")
          bath_size = Norb*Nbath + Norb*Nbath + Norb*Nbath
          !( e [Nspin][Norb][Nbath] + v [Nspin][Norb][Nbath] + u [Nspin][Norb][Nbath] )
       end select
       bath_size=Nspin*bath_size
       !
    case('hybrid')
       select case(ed_mode)
       case default          
          bath_size = Nbath + Norb*Nbath
          !(e [Nspin][1][Nbath] + v [Nspin][Norb][Nbath] )
       case ("superc")
          bath_size = Nbath + Nbath + Norb*Nbath
          !(e [Nspin][1][Nbath] + d [Nspin][1][Nbath] + v [Nspin][Norb][Nbath] )
       case ("nonsu2")
          bath_size = Nbath + Norb*Nbath + Norb*Nbath
          !(e [Nspin][1][Nbath] + v [Nspin][Norb][Nbath] + u [Nspin][Norb][Nbath] )
       end select
       bath_size=Nspin*bath_size
       !
    case('replica')
       allocate(Hloc(Nspin,Nspin,Norb,Norb))
       if(present(Hloc_nn))then              !User defined Hloc_nn 
          Hloc=Hloc_nn
       elseif(Hreplica_status)then !User defined Hreplica_basis
          Hloc=Hreplica_build(Hreplica_lambda)
       else                                  !Error:
          deallocate(Hloc)
          stop "ERROR get_bath_dimension_direct: ed_mode=replica neither Hloc_nn present nor Hreplica_basis defined"
       endif
       !
       !Check Hermiticity:
       do ispin=1,Nspin
          do iorb=1,Norb
             if(abs(dimag(Hloc(ispin,ispin,iorb,iorb))).gt.1d-6)stop "Hloc is not Hermitian"
          enddo
       enddo
       !
       !Re/Im off-diagonal non-vanishing elements
       ndx=0
       do ispin=1,Nspin
          do jspin=1,Nspin
             do iorb=1,Norb
                do jorb=1,Norb
                   io = iorb + (ispin-1)*Norb
                   jo = jorb + (jspin-1)*Norb
                   if(io > jo)cycle
                   if(dreal(Hloc(ispin,jspin,iorb,jorb)) /= 0d0)ndx=ndx+1
                   if(dimag(Hloc(ispin,jspin,iorb,jorb)) /= 0d0)ndx=ndx+1
                enddo
             enddo
          enddo
       enddo
       !
       ndx = ndx * Nbath !number of non vanishing elements for each replica
       ndx = ndx + Nbath !diagonal hybridizations: Vs (different per spin)
       ndx = ndx + 1     !we also print Nbasis
       bath_size = ndx
    end select
  end function get_bath_dimension_direct

  function get_bath_dimension_symmetries(Hloc_nn) result(bath_size)
    complex(8),dimension(:,:,:,:,:),intent(in) :: Hloc_nn
    integer                                    :: bath_size,ndx,isym,Nsym
    !
    !number of symmetries
    Nsym=size(Hloc_nn,5)
    if(Nsym/=size(Hreplica_lambda))stop "ERROR get_bath_dimension_symmetries:  neither Hloc_nn present nor Hreplica_basis defined"
    !
    ndx=Nsym
    !
    !number of replicas
    ndx = ndx * Nbath
    !diagonal hybridizations: Vs
    ndx = ndx + Nbath
    !
    !include Nbasis
    ndx=ndx+1
    !
    bath_size = ndx
    !
  end function get_bath_dimension_symmetries



  !+-------------------------------------------------------------------+
  !PURPOSE  : Check if the dimension of the bath array are consistent
  !+-------------------------------------------------------------------+
  function check_bath_dimension(bath_) result(bool)
    real(8),dimension(:)           :: bath_
    integer                        :: Ntrue,i
    logical                        :: bool
    complex(8),allocatable         :: Hreplica(:,:,:,:,:)![Nspin][:][Norb][:][Nsym]
    select case (bath_type)
    case default
       Ntrue = get_bath_dimension()
    case ('replica')
       if(.not.Hreplica_status)STOP "check_bath_dimension: Hreplica_basis not allocated"
       if(.not.allocated(Hreplica))allocate(Hreplica(Nspin,Nspin,Norb,Norb,size(Hreplica_basis)))
       do i=1,size(Hreplica_basis)
          Hreplica(:,:,:,:,i)=Hreplica_basis(i)%O
       enddo
       Ntrue   = get_bath_dimension_symmetries(Hreplica)
    end select
    bool  = ( size(bath_) == Ntrue )
  end function check_bath_dimension





  














  !##################################################################
  !
  !     USER BATH  SYMMETRIES: PREDEFINED AND USER CONTROLLED
  !
  !##################################################################

  !+-------------------------------------------------------------------+
  !PURPOSE  : given a bath array apply a specific transformation or 
  ! impose a given symmetry:
  ! - break spin symmetry by applying a symmetry breaking field
  ! - given a bath array set both spin components to have 
  !    the same bath, i.e. impose non-magnetic solution
  ! - given a bath array enforces the particle-hole symmetry 
  !    by setting the positive energies in modulo identical to the negative
  !    ones.
  ! - given a bath enforce normal (i.e. non superconducting) solution
  ! - given a dmft bath pull/push the components W^{ss'}_\a(l) of the Hybridization 
  !    matrix
  ! - given a dmft bath pull/push the nonsu2 components
  !+-------------------------------------------------------------------+
  subroutine impose_equal_lambda(bath_,ibath,lambdaindex_vec)
    real(8),dimension(:) :: bath_
    type(effective_bath) :: dmft_bath_
    real(8)              :: val
    integer,dimension(:) :: lambdaindex_vec
    integer              :: i,N,ibath
    !
    call allocate_dmft_bath(dmft_bath_)
    call set_dmft_bath(bath_,dmft_bath_)
    !
    N=size(lambdaindex_vec)
    val=0.d0
    do i=1,N
       val=val+dmft_bath_%item(ibath)%lambda(lambdaindex_vec(i))/N
    enddo
    !
    do i=1,N
       dmft_bath_%item(ibath)%lambda(lambdaindex_vec(i))=val
    enddo
    !
    call get_dmft_bath(dmft_bath_,bath_)
    call deallocate_dmft_bath(dmft_bath_)
  end subroutine impose_equal_lambda


  subroutine impose_bath_offset(bath_,ibath,offset)
    real(8),dimension(:) :: bath_
    type(effective_bath) :: dmft_bath_
    real(8)              :: offset
    integer              :: isym,N,ibath
    !
    call allocate_dmft_bath(dmft_bath_)
    call set_dmft_bath(bath_,dmft_bath_)
    !
    if(size(Hreplica_basis) .ne. dmft_bath_%Nbasis)then
       dmft_bath_%item(ibath)%lambda(dmft_bath_%Nbasis)=offset
    else
       do isym=1,size(Hreplica_basis)
          if(is_identity(Hreplica_basis(isym)%O)) dmft_bath_%item(ibath)%lambda(isym)=offset
          return
       enddo
    endif
    !
    call get_dmft_bath(dmft_bath_,bath_)
    call deallocate_dmft_bath(dmft_bath_)
    !
  end subroutine impose_bath_offset


  subroutine break_symmetry_bath_site(bath_,field,sign,save)
    real(8),dimension(:)   :: bath_
    type(effective_bath)   :: dmft_bath_
    real(8)                :: field
    real(8)                :: sign
    logical,optional       :: save
    logical                :: save_
    if(bath_type=="replica")stop "break_symmetry_bath_site ERROR: can not be used with bath_type=replica"
    save_=.true.;if(present(save))save_=save
    call allocate_dmft_bath(dmft_bath_)
    call set_dmft_bath(bath_,dmft_bath_)
    dmft_bath_%e(1,:,:)    =dmft_bath_%e(1,:,:)      + sign*field
    dmft_bath_%e(Nspin,:,:)=dmft_bath_%e(Nspin,:,:)  - sign*field
    if(save_)call save_dmft_bath(dmft_bath_)
    call get_dmft_bath(dmft_bath_,bath_)
    call deallocate_dmft_bath(dmft_bath_)
  end subroutine break_symmetry_bath_site
  !
  subroutine break_symmetry_bath_lattice(bath_,field,sign,save)
    real(8),dimension(:,:) :: bath_
    real(8)                :: field
    real(8)                :: sign
    logical,optional       :: save
    logical                :: save_
    integer                :: Nsites,ilat
    save_=.true.;if(present(save))save_=save
    Nsites=size(bath_,1)
    do ilat=1,Nsites
       ed_file_suffix=reg(ineq_site_suffix)//reg(txtfy(ilat,site_indx_padding))
       call break_symmetry_bath_site(bath_(ilat,:),field,sign,save_)
    enddo
    ed_file_suffix=""
  end subroutine break_symmetry_bath_lattice

  !---------------------------------------------------------!


  subroutine spin_symmetrize_bath_site(bath_,save)
    real(8),dimension(:)   :: bath_
    type(effective_bath)   :: dmft_bath_
    logical,optional       :: save
    logical                :: save_
    integer :: ibath
    if(bath_type=="replica")stop "spin_symmetry_bath_site ERROR: can not be used with bath_type=replica"
    save_=.true.;if(present(save))save_=save
    if(Nspin==1)then
       write(LOGfile,"(A)")"spin_symmetrize_bath: Nspin=1 nothing to symmetrize"
       return
    endif
    !
    call allocate_dmft_bath(dmft_bath_)
    call set_dmft_bath(bath_,dmft_bath_)
    select case(ed_mode)
    case default
       dmft_bath_%e(Nspin,:,:)=dmft_bath_%e(1,:,:)
       dmft_bath_%v(Nspin,:,:)=dmft_bath_%v(1,:,:)
    case ("superc")
       dmft_bath_%e(Nspin,:,:)=dmft_bath_%e(1,:,:)
       dmft_bath_%v(Nspin,:,:)=dmft_bath_%v(1,:,:)
       dmft_bath_%d(Nspin,:,:)=dmft_bath_%d(1,:,:)
    end select
    if(save_)call save_dmft_bath(dmft_bath_)
    call get_dmft_bath(dmft_bath_,bath_)
    call deallocate_dmft_bath(dmft_bath_)
  end subroutine spin_symmetrize_bath_site
  subroutine spin_symmetrize_bath_lattice(bath_,save)
    real(8),dimension(:,:) :: bath_
    logical,optional       :: save
    logical                :: save_
    integer                :: Nsites,ilat
    save_=.true.;if(present(save))save_=save
    Nsites=size(bath_,1)
    do ilat=1,Nsites
       ed_file_suffix=reg(ineq_site_suffix)//reg(txtfy(ilat,site_indx_padding))
       call spin_symmetrize_bath_site(bath_(ilat,:),save_)
    enddo
    ed_file_suffix=""
  end subroutine spin_symmetrize_bath_lattice

  !---------------------------------------------------------!

  subroutine orb_symmetrize_bath_site(bath_,save)
    real(8),dimension(:)   :: bath_
    type(effective_bath)   :: dmft_bath_
    logical,optional       :: save
    logical                :: save_
    integer                :: iorb
    real(8),allocatable    :: lvl(:,:),hyb(:,:)
    if(bath_type=="replica")stop "orb_symmetry_bath_site ERROR: can not be used with bath_type=replica"
    save_=.true.;if(present(save))save_=save
    if(Norb==1)then
       write(LOGfile,"(A)")"orb_symmetrize_bath: Norb=1 nothing to symmetrize"
       return
    endif
    !
    call allocate_dmft_bath(dmft_bath_)
    ! if (bath_type=="replica")call init_dmft_bath_mask(dmft_bath_)
    call set_dmft_bath(bath_,dmft_bath_)
    !
    if(allocated(lvl))deallocate(lvl);allocate(lvl(Nspin,Nbath));lvl=0d0;lvl=sum(dmft_bath_%e,dim=2)/Norb
    if(allocated(hyb))deallocate(hyb);allocate(hyb(Nspin,Nbath));hyb=0d0;hyb=sum(dmft_bath_%v,dim=2)/Norb
    do iorb=1,Norb
       dmft_bath_%e(:,iorb,:)=lvl
       dmft_bath_%v(:,iorb,:)=hyb
    enddo
    !
    if(save_)call save_dmft_bath(dmft_bath_)
    call get_dmft_bath(dmft_bath_,bath_)
    call deallocate_dmft_bath(dmft_bath_)
  end subroutine orb_symmetrize_bath_site
  subroutine orb_symmetrize_bath_lattice(bath_,save)
    real(8),dimension(:,:) :: bath_
    logical,optional       :: save
    logical                :: save_
    integer                :: Nsites,ilat
    if(bath_type=="replica")stop "orb_symmetry_bath_site ERROR: can not be used with bath_type=replica"
    save_=.true.;if(present(save))save_=save
    Nsites=size(bath_,1)
    do ilat=1,Nsites
       ed_file_suffix=reg(ineq_site_suffix)//reg(txtfy(ilat,site_indx_padding))
       call orb_symmetrize_bath_site(bath_(ilat,:),save_)
    enddo
    ed_file_suffix=""
  end subroutine orb_symmetrize_bath_lattice

  !---------------------------------------------------------!


  subroutine orb_equality_bath_site(bath_,indx,save)
    real(8),dimension(:)   :: bath_
    type(effective_bath)   :: dmft_bath_
    integer,optional       :: indx
    logical,optional       :: save
    integer                :: indx_
    logical                :: save_
    integer                :: iorb
    real(8),allocatable    :: lvl(:,:),hyb(:,:)
    if(bath_type=="replica")stop "orb_equality_bath_site ERROR: can not be used with bath_type=replica"
    indx_=1     ;if(present(indx))indx_=indx
    save_=.true.;if(present(save))save_=save
    if(Norb==1)then
       write(LOGfile,"(A)")"orb_symmetrize_bath: Norb=1 nothing to symmetrize"
       return
    endif
    !
    call allocate_dmft_bath(dmft_bath_)
    ! if (bath_type=="replica")call init_dmft_bath_mask(dmft_bath_)
    call set_dmft_bath(bath_,dmft_bath_)
    !
    if(allocated(lvl))deallocate(lvl);allocate(lvl(Nspin,Nbath));lvl=0d0;lvl=dmft_bath_%e(:,indx_,:)
    if(allocated(hyb))deallocate(hyb);allocate(hyb(Nspin,Nbath));hyb=0d0;hyb=dmft_bath_%v(:,indx_,:)
    do iorb=1,Norb
       if(iorb==indx_)cycle
       dmft_bath_%e(:,iorb,:)=lvl
       dmft_bath_%v(:,iorb,:)=hyb
    enddo
    !
    if(save_)call save_dmft_bath(dmft_bath_)
    call get_dmft_bath(dmft_bath_,bath_)
    call deallocate_dmft_bath(dmft_bath_)
  end subroutine orb_equality_bath_site
  subroutine orb_equality_bath_lattice(bath_,indx,save)
    real(8),dimension(:,:) :: bath_
    integer,optional       :: indx
    logical,optional       :: save
    integer                :: indx_
    logical                :: save_
    integer                :: iorb
    integer                :: Nsites,ilat
    if(bath_type=="replica")stop "orb_equality_bath_site ERROR: can not be used with bath_type=replica"
    indx_=1     ;if(present(indx))indx_=indx
    save_=.true.;if(present(save))save_=save
    Nsites=size(bath_,1)
    do ilat=1,Nsites
       ed_file_suffix=reg(ineq_site_suffix)//reg(txtfy(ilat,site_indx_padding))
       call orb_equality_bath_site(bath_(ilat,:),indx_,save_)
    enddo
    ed_file_suffix=""
  end subroutine orb_equality_bath_lattice



  !---------------------------------------------------------!

  subroutine ph_symmetrize_bath_site(bath_,save)
    real(8),dimension(:)   :: bath_
    type(effective_bath)   :: dmft_bath_
    integer                :: i
    logical,optional       :: save
    logical                :: save_
    if(bath_type=="replica")stop "ph_symmetry_bath_site ERROR: can not be used with bath_type=replica"
    save_=.true.;if(present(save))save_=save
    call allocate_dmft_bath(dmft_bath_)
    call set_dmft_bath(bath_,dmft_bath_)
    if(Nbath==1)return
    if(mod(Nbath,2)==0)then
       do i=1,Nbath/2
          dmft_bath_%e(:,:,Nbath+1-i)=-dmft_bath_%e(:,:,i)
          dmft_bath_%v(:,:,Nbath+1-i)= dmft_bath_%v(:,:,i)
          if(ed_mode=="superc")dmft_bath_%d(:,:,Nbath+1-i)=dmft_bath_%d(:,:,i)
       enddo
    else
       do i=1,(Nbath-1)/2
          dmft_bath_%e(:,:,Nbath+1-i)=-dmft_bath_%e(:,:,i)
          dmft_bath_%v(:,:,Nbath+1-i)= dmft_bath_%v(:,:,i)
          if(ed_mode=="superc")dmft_bath_%d(:,:,Nbath+1-i)=dmft_bath_%d(:,:,i)
       enddo
       dmft_bath_%e(:,:,(Nbath-1)/2+1)=0.d0
    endif
    if(save_)call save_dmft_bath(dmft_bath_)
    call get_dmft_bath(dmft_bath_,bath_)
    call deallocate_dmft_bath(dmft_bath_)
  end subroutine ph_symmetrize_bath_site
  subroutine ph_symmetrize_bath_lattice(bath_,save)
    real(8),dimension(:,:) :: bath_
    logical,optional       :: save
    logical                :: save_
    integer                :: Nsites,ilat
    if(bath_type=="replica")stop "ph_symmetry_bath_site ERROR: can not be used with bath_type=replica"
    save_=.true.;if(present(save))save_=save
    Nsites=size(bath_,1)
    do ilat=1,Nsites
       ed_file_suffix=reg(ineq_site_suffix)//reg(txtfy(ilat,site_indx_padding))
       call ph_symmetrize_bath_site(bath_(ilat,:),save_)
    enddo
    ed_file_suffix=""
  end subroutine ph_symmetrize_bath_lattice

  !---------------------------------------------------------!

  subroutine ph_trans_bath_site(bath_,save)
    real(8),dimension(:)   :: bath_
    type(effective_bath)   :: dmft_bath_
    type(effective_bath)   :: tmp_dmft_bath
    integer                :: i
    logical,optional       :: save
    logical                :: save_
    if(bath_type=="replica")stop "ph_trans_bath_site ERROR: can not be used with bath_type=replica"
    save_=.true.;if(present(save))save_=save
    call allocate_dmft_bath(dmft_bath_)
    call allocate_dmft_bath(tmp_dmft_bath)
    call set_dmft_bath(bath_,dmft_bath_)
    if(Nbath==1)return
    do i=1,Nbath
       select case(Norb)
       case default
          ! do nothing
          dmft_bath_%e(:,:,i)= dmft_bath_%e(:,:,i)
          dmft_bath_%v(:,:,i)= dmft_bath_%v(:,:,i)
       case(1)
          dmft_bath_%e(:,:,i)= -dmft_bath_%e(:,:,i)
          dmft_bath_%v(:,:,i)=  dmft_bath_%v(:,:,i)
       case(2)
          tmp_dmft_bath%e(:,1,i) = -dmft_bath_%e(:,2,i)
          tmp_dmft_bath%e(:,2,i) = -dmft_bath_%e(:,1,i)
          dmft_bath_%e(:,:,i)    = tmp_dmft_bath%e(:,:,i)
          tmp_dmft_bath%v(:,1,i) = dmft_bath_%v(:,2,i)
          tmp_dmft_bath%v(:,2,i) = dmft_bath_%v(:,1,i)
          dmft_bath_%v(:,:,i)    = tmp_dmft_bath%v(:,:,i)
       end select
    end do
    if(save_)call save_dmft_bath(dmft_bath_)
    call get_dmft_bath(dmft_bath_,bath_)
    call deallocate_dmft_bath(dmft_bath_)
  end subroutine ph_trans_bath_site
  subroutine ph_trans_bath_lattice(bath_,save)
    real(8),dimension(:,:) :: bath_
    logical,optional       :: save
    logical                :: save_
    integer                :: Nsites,ilat
    if(bath_type=="replica")stop "ph_trans_bath_site ERROR: can not be used with bath_type=replica"
    save_=.true.;if(present(save))save_=save
    Nsites=size(bath_,1)
    do ilat=1,Nsites
       ed_file_suffix=reg(ineq_site_suffix)//reg(txtfy(ilat,site_indx_padding))
       call ph_trans_bath_site(bath_(ilat,:),save_)
    enddo
    ed_file_suffix=""
  end subroutine ph_trans_bath_lattice

  !---------------------------------------------------------!

  subroutine enforce_normal_bath_site(bath_,save)
    real(8),dimension(:)   :: bath_
    type(effective_bath)   :: dmft_bath_
    logical,optional       :: save
    logical                :: save_
    save_=.true.;if(present(save))save_=save
    call allocate_dmft_bath(dmft_bath_)
    call set_dmft_bath(bath_,dmft_bath_)
    if(ed_mode=="superc")dmft_bath_%d(:,:,:)=0.d0
    if(save_)call save_dmft_bath(dmft_bath_)
    call get_dmft_bath(dmft_bath_,bath_)
    call deallocate_dmft_bath(dmft_bath_)
  end subroutine enforce_normal_bath_site
  subroutine enforce_normal_bath_lattice(bath_,save)
    real(8),dimension(:,:) :: bath_
    logical,optional       :: save
    logical                :: save_
    integer                :: Nsites,ilat
    save_=.true.;if(present(save))save_=save
    Nsites=size(bath_,1)
    do ilat=1,Nsites
       ed_file_suffix=reg(ineq_site_suffix)//reg(txtfy(ilat,site_indx_padding))
       call enforce_normal_bath_site(bath_(ilat,:),save_)
    enddo
    ed_file_suffix=""
  end subroutine enforce_normal_bath_lattice










  !+-----------------------------------------------------------------------------+!
  !PURPOSE:  check if the specified itype is consistent with the input parameters.
  !+-----------------------------------------------------------------------------+!
  subroutine check_bath_component(type)
    character(len=1) :: type
    select case(bath_type)
    case default
       select case(ed_mode)
       case default
          if(type/="e".OR.type/='v')stop "check_bath_component error: type!=e,v"
       case ("superc")
          if(type/="e".OR.type/='v'.OR.type/='d')stop "check_bath_component error: type!=e,v,d"
       case ("nonsu2")
          if(type/="e".OR.type/='v'.OR.type/='u')stop "check_bath_component error: type!=e,v,u"
       end select
    case ("replica")
       if(type/="v".OR.type/="l")stop "check_bath_component error: type!=v,l"
    end select
    return
  end subroutine check_bath_component


  !+-------------------------------------------------------------------+
  !PURPOSE  : Inquire the correct bath size to allocate the 
  ! the bath array in the calling program.
  !
  ! Get size of each dimension of the component array. 
  ! The Result is an rank 1 integer array Ndim with dimension:
  ! 3 for get_component_size_bath
  ! 2 for get_spin_component_size_bath & get_orb_component_size_bath
  ! 1 for get_spin_orb_component_size_bath
  !+-------------------------------------------------------------------+
  function get_bath_component_dimension(type) result(Ndim)
    character(len=1) :: type
    integer          :: Ndim(3)
    call  check_bath_component(type)
    select case(bath_type)
    case default
       Ndim=[Nspin,Norb,Nbath]
    case('hybrid')
       select case(ed_mode)
       case default
          select case(type)
          case('e')
             Ndim=[Nspin,1,Nbath]
          case('v')
             Ndim=[Nspin,Norb,Nbath]
          end select
       case ("superc")
          select case(type)
          case('e','d')
             Ndim=[Nspin,1,Nbath]
          case('v')
             Ndim=[Nspin,Norb,Nbath]
          end select
       case ("nonsu2")
          select case(type)
          case('e')
             Ndim=[Nspin,1,Nbath]
          case('v','u')
             Ndim=[Nspin,Norb,Nbath]
          end select
       end select
    end select
  end function get_bath_component_dimension


  !+-----------------------------------------------------------------------------+!
  !PURPOSE: check that the input array hsa the correct dimensions specified 
  ! for the choice of itype and possiblty ispin and/or iorb.
  !+-----------------------------------------------------------------------------+!
  subroutine assert_bath_component_size(array,type,string1,string2)
    real(8),dimension(:,:,:) :: array
    character(len=1)         :: type
    character(len=*)         :: string1,string2
    integer                  :: Ndim(3)
    Ndim = get_bath_component_dimension(type)
    call assert_shape(Array,Ndim,reg(string1),reg(string2))
  end subroutine assert_bath_component_size








  !+-----------------------------------------------------------------------------+!
  !PURPOSE: Get a specified itype,ispin,iorb component of the user bath.
  ! The component is returned into an Array of rank D
  ! get_full_component_bath    : return the entire itype component (D=3)
  ! get_spin_component_bath    : return the itype component for the select ispin (D=2)
  ! get_spin_orb_component_bath: return the itype component for the select ispin & iorb (D=1)
  !+-----------------------------------------------------------------------------+!
  subroutine get_bath_component(array,bath_,type)
    real(8),dimension(:,:,:) :: array
    real(8),dimension(:)     :: bath_
    character(len=1)         :: type
    logical                  :: check
    type(effective_bath)     :: dmft_bath_
    !
    check= check_bath_dimension(bath_)
    if(.not.check)stop "get_component_bath error: wrong bath dimensions"
    call allocate_dmft_bath(dmft_bath_)
    call set_dmft_bath(bath_,dmft_bath_)
    call assert_bath_component_size(array,type,"get_bath_component","Array")
    call check_bath_component(type)
    select case(ed_mode)
    case default
       select case(type)
       case('e')
          Array = dmft_bath_%e(:,:,:)
       case('v')
          Array = dmft_bath_%v(:,:,:)
       end select
    case ("superc")
       select case(type)
       case('e')
          Array = dmft_bath_%e(:,:,:)           
       case('d')
          Array = dmft_bath_%d(:,:,:)
       case('v')
          Array = dmft_bath_%v(:,:,:)
       end select
    case ("nonsu2")
       select case(type)
       case('e')
          Array = dmft_bath_%e(:,:,:)           
       case('v')
          Array = dmft_bath_%v(:,:,:)
       case('u')
          Array = dmft_bath_%u(:,:,:)
       end select
    end select
    call deallocate_dmft_bath(dmft_bath_)
  end subroutine get_bath_component


  !+-----------------------------------------------------------------------------+!
  !PURPOSE: Set a specified itype,ispin,iorb component of the user bath.
  !+-----------------------------------------------------------------------------+!
  subroutine set_bath_component(array,bath_,type)
    real(8),dimension(:,:,:) :: array
    real(8),dimension(:)     :: bath_
    character(len=1)         :: type
    logical                  :: check
    type(effective_bath)     :: dmft_bath_
    !
    check= check_bath_dimension(bath_)
    if(.not.check)stop "set_component_bath error: wrong bath dimensions"
    call allocate_dmft_bath(dmft_bath_)
    call set_dmft_bath(bath_,dmft_bath_)
    call assert_bath_component_size(array,type,"set_bath_component","Array")
    call check_bath_component(type)
    select case(ed_mode)
    case default
       select case(type)
       case('e')
          dmft_bath_%e(:,:,:) = Array 
       case('v')
          dmft_bath_%v(:,:,:) = Array
       end select
    case ("superc")
       select case(type)
       case('e')
          dmft_bath_%e(:,:,:) = Array   
       case('d')
          dmft_bath_%d(:,:,:) = Array
       case('v')
          dmft_bath_%v(:,:,:) = Array
       end select
    case ("nonsu2")
       select case(type)
       case('e')
          dmft_bath_%e(:,:,:) = Array   
       case('v')
          dmft_bath_%v(:,:,:) = Array
       case('u')
          dmft_bath_%u(:,:,:) = Array
       end select
    end select
    call get_dmft_bath(dmft_bath_,bath_)
    call deallocate_dmft_bath(dmft_bath_)
  end subroutine set_bath_component



  !+-----------------------------------------------------------------------------+!
  !PURPOSE: Copy a specified component of IN bath to the OUT bath.
  !+-----------------------------------------------------------------------------+!
  subroutine copy_bath_component(bathIN,bathOUT,type)
    real(8),dimension(:)     :: bathIN,bathOUT
    character(len=1)         :: type
    logical                  :: check
    type(effective_bath)     :: dIN,dOUT
    !
    check= check_bath_dimension(bathIN)
    if(.not.check)stop "copy_component_bath error: wrong bath dimensions IN"
    check= check_bath_dimension(bathOUT)
    if(.not.check)stop "copy_component_bath error: wrong bath dimensions OUT"
    call allocate_dmft_bath(dIN)
    call allocate_dmft_bath(dOUT)
    call set_dmft_bath(bathIN,dIN)
    call set_dmft_bath(bathOUT,dOUT)
    call check_bath_component(type)
    select case(ed_mode)
    case default
       select case(type)
       case('e')
          dOUT%e(:,:,:)  = dIN%e(:,:,:)
       case('v')
          dOUT%v(:,:,:)  = dIN%v(:,:,:)
       end select
    case ("superc")
       select case(type)
       case('e')
          dOUT%e(:,:,:)  = dIN%e(:,:,:)
       case('d')
          dOUT%d(:,:,:)  = dIN%d(:,:,:)
       case('v')
          dOUT%v(:,:,:)  = dIN%v(:,:,:)
       end select
    case ("nonsu2")
       select case(type)
       case('e')
          dOUT%e(:,:,:)  = dIN%e(:,:,:)
       case('v')
          dOUT%v(:,:,:)  = dIN%v(:,:,:)
       case('u')
          dOUT%u(:,:,:)  = dIN%u(:,:,:)
       end select
    end select
    call get_dmft_bath(dOUT,bathOUT)
    call deallocate_dmft_bath(dIN)
    call deallocate_dmft_bath(dOUT)
  end subroutine copy_bath_component





























  !##################################################################
  !
  !     DMFT BATH ROUTINES:
  !
  !##################################################################
  !+-------------------------------------------------------------------+
  !PURPOSE  : Allocate the ED bath
  !+-------------------------------------------------------------------+
  subroutine allocate_dmft_bath(dmft_bath_)
    type(effective_bath) :: dmft_bath_
    integer              :: Nsym,ibath
#ifdef _DEBUG
    write(Logfile,"(A)")"DEBUG allocate_dmft_bath"
#endif
    if(dmft_bath_%status)call deallocate_dmft_bath(dmft_bath_)
    !
    select case(bath_type)
    case default
       !
       select case(ed_mode)
       case default                                 !normal [N,Sz]
          allocate(dmft_bath_%e(Nspin,Norb,Nbath))  !local energies of the bath
          allocate(dmft_bath_%v(Nspin,Norb,Nbath))  !same-spin hybridization 
       case ("superc")                              !superc [Sz] 
          allocate(dmft_bath_%e(Nspin,Norb,Nbath))  !local energies of the bath
          allocate(dmft_bath_%d(Nspin,Norb,Nbath))  !local SC order parameters the bath
          allocate(dmft_bath_%v(Nspin,Norb,Nbath))  !same-spin hybridization 
       case ("nonsu2")                              !nonsu2 [N]
          allocate(dmft_bath_%e(Nspin,Norb,Nbath))  !local energies of the bath
          allocate(dmft_bath_%v(Nspin,Norb,Nbath))  !same-spin hybridization 
          allocate(dmft_bath_%u(Nspin,Norb,Nbath))  !spin-flip hybridization
       end select
       !
    case('hybrid')
       !
       select case(ed_mode)
       case default                                 !normal  [N,Sz]
          allocate(dmft_bath_%e(Nspin,1,Nbath))     !local energies of the bath
          allocate(dmft_bath_%v(Nspin,Norb,Nbath))  !same-spin hybridization 
       case ("superc")                              !superc  [Sz]
          allocate(dmft_bath_%e(Nspin,1,Nbath))     !local energies of the bath
          allocate(dmft_bath_%d(Nspin,1,Nbath))     !local SC order parameters the bath
          allocate(dmft_bath_%v(Nspin,Norb,Nbath))  !same-spin hybridization 
       case ("nonsu2")                              !nonsu2 case [N] qn
          allocate(dmft_bath_%e(Nspin,1,Nbath))     !local energies of the bath
          allocate(dmft_bath_%v(Nspin,Norb,Nbath))  !same-spin hybridization 
          allocate(dmft_bath_%u(Nspin,Norb,Nbath))  !spin-flip hybridization
       end select
       !
    case('replica')
       !
       if(.not.Hreplica_status)stop "ERROR allocate_dmft_bath: Hreplica_basis not allocated"
       call deallocate_dmft_bath(dmft_bath_)     !
       Nsym=size(Hreplica_basis)
       !     
       allocate(dmft_bath_%item(Nbath))
       dmft_Bath_%Nbasis=Nsym
       do ibath=1,Nbath
          allocate(dmft_bath_%item(ibath)%lambda(Nsym))
       enddo
       !
    end select
    !
    dmft_bath_%status=.true.
    !
  end subroutine allocate_dmft_bath


  !+-------------------------------------------------------------------+
  !PURPOSE  : Deallocate the ED bath
  !+-------------------------------------------------------------------+
  subroutine deallocate_dmft_bath(dmft_bath_)
    type(effective_bath) :: dmft_bath_
    integer              :: ibath,isym
#ifdef _DEBUG
    write(Logfile,"(A)")"DEBUG deallocate_dmft_bath"
#endif
    if(.not.dmft_bath_%status)return
    if(allocated(dmft_bath_%e))   deallocate(dmft_bath_%e)
    if(allocated(dmft_bath_%d))   deallocate(dmft_bath_%d)
    if(allocated(dmft_bath_%v))   deallocate(dmft_bath_%v)
    if(allocated(dmft_bath_%u))   deallocate(dmft_bath_%u)
    if(bath_type=="replica")then
       dmft_bath_%Nbasis= 0
       do ibath=1,Nbath
          deallocate(dmft_bath_%item(ibath)%lambda)
       enddo
       deallocate(dmft_bath_%item)
    endif
    dmft_bath_%status=.false.
  end subroutine deallocate_dmft_bath






  !+------------------------------------------------------------------+
  !PURPOSE  : Initialize the DMFT loop, builindg H parameters and/or 
  !reading previous (converged) solution
  !+------------------------------------------------------------------+
  subroutine init_dmft_bath(dmft_bath_,used)
    type(effective_bath) :: dmft_bath_
    logical,optional     :: used
    integer              :: Nbasis
    integer              :: i,unit,flen,Nh,isym,Nsym
    integer              :: io,jo,iorb,ispin,jorb,jspin,ibath
    logical              :: IOfile,used_
    real(8)              :: de
    real(8)              :: offset(Nbath)
    character(len=20)    :: hsuffix
    !
#ifdef _DEBUG
    write(Logfile,"(A)")"DEBUG init_dmft_bath"
#endif
    used_   = .false.   ;if(present(used))used_=used
    hsuffix = ".restart";if(used_)hsuffix=reg(".used")
    if(.not.dmft_bath_%status)stop "ERROR init_dmft_bath error: bath not allocated"
    !
    select case(bath_type)
    case default
       !Get energies:
       dmft_bath_%e(:,:,1)    =-ed_hw_bath
       dmft_bath_%e(:,:,Nbath)= ed_hw_bath
       Nh=Nbath/2
       if(mod(Nbath,2)==0.and.Nbath>=4)then
          de=ed_hw_bath/max(Nh-1,1)
          dmft_bath_%e(:,:,Nh)  = -1.d-1
          dmft_bath_%e(:,:,Nh+1)=  1.d-1
          do i=2,Nh-1
             dmft_bath_%e(:,:,i)   =-ed_hw_bath + (i-1)*de
             dmft_bath_%e(:,:,Nbath-i+1)= ed_hw_bath - (i-1)*de
          enddo
       elseif(mod(Nbath,2)/=0.and.Nbath>=3)then
          de=ed_hw_bath/Nh
          dmft_bath_%e(:,:,Nh+1)= 0d0
          do i=2,Nh
             dmft_bath_%e(:,:,i)        =-ed_hw_bath + (i-1)*de
             dmft_bath_%e(:,:,Nbath-i+1)= ed_hw_bath - (i-1)*de
          enddo
       endif
       !Get spin-keep yhbridizations
       do i=1,Nbath
          dmft_bath_%v(:,:,i)=max(0.1d0,1d0/sqrt(dble(Nbath)))
       enddo
       !Get SC amplitudes
       if(ed_mode=="superc")dmft_bath_%d(:,:,:)=deltasc
       !Get spin-flip hybridizations
       if(ed_mode=="nonsu2")then
          do i=1,Nbath
             dmft_bath_%u(:,:,i) = dmft_bath_%v(:,:,i)!*ed_vsf_ratio
          enddo
       endif
       !
    case('replica')     
       offset=0.d0
       if(Nbath>1) offset=linspace(-ed_offset_bath,ed_offset_bath,Nbath)
       !     
       !BATH V INITIALIZATION
       do ibath=1,Nbath
          dmft_bath%item(ibath)%v=max(0.1d0,1d0/sqrt(dble(Nbath)))
       enddo
       !
       !BATH LAMBDAS INITIALIZATION
       !Do not need to check for Hreplica_basis: this is done at allocation time of the dmft_bath.
       Nsym = dmft_bath%Nbasis
       do isym=1,Nsym
          do ibath=1,Nbath
             dmft_bath%item(ibath)%lambda(isym) =  Hreplica_lambda(isym)
          enddo
          if(is_diagonal(Hreplica_basis(isym)%O))then
             offset=linspace(-ed_offset_bath,ed_offset_bath,Nbath)
             do ibath=1,Nbath
                dmft_bath%item(ibath)%lambda(isym) =  Hreplica_lambda(isym) + offset(ibath)
             enddo
          endif
       enddo
       !
    end select
    !
    !
    !
    !Read from file if exist:
    inquire(file=trim(Hfile)//trim(ed_file_suffix)//trim(hsuffix),exist=IOfile)
    if(IOfile)then
       write(LOGfile,"(A)")'Reading bath from file'//trim(Hfile)//trim(ed_file_suffix)//trim(hsuffix)
       unit = free_unit()
       flen = file_length(trim(Hfile)//trim(ed_file_suffix)//trim(hsuffix))
       !
       open(unit,file=trim(Hfile)//trim(ed_file_suffix)//trim(hsuffix))
       !
       select case(bath_type)
       case default
          !
          read(unit,*)
          select case(ed_mode)
          case default
             do i=1,min(flen,Nbath)
                read(unit,*)((&
                     dmft_bath_%e(ispin,iorb,i),&
                     dmft_bath_%v(ispin,iorb,i),&
                     iorb=1,Norb),ispin=1,Nspin)
             enddo
          case ("superc")
             do i=1,min(flen,Nbath)
                read(unit,*)((&
                     dmft_bath_%e(ispin,iorb,i),&
                     dmft_bath_%d(ispin,iorb,i),&
                     dmft_bath_%v(ispin,iorb,i),&
                     iorb=1,Norb),ispin=1,Nspin)
             enddo
          case("nonsu2")
             do i=1,min(flen,Nbath)
                read(unit,*)((&
                     dmft_bath_%e(ispin,iorb,i),&
                     dmft_bath_%v(ispin,iorb,i),&
                     dmft_bath_%u(ispin,iorb,i),&
                     iorb=1,Norb),ispin=1,Nspin)
             enddo
          end select
          !
       case ('hybrid')
          read(unit,*)
          !
          select case(ed_mode)
          case default
             do i=1,min(flen,Nbath)
                read(unit,*)(&
                     dmft_bath_%e(ispin,1,i),&
                     (&
                     dmft_bath_%v(ispin,iorb,i),&
                     iorb=1,Norb),&
                     ispin=1,Nspin)
             enddo
          case ("superc")
             do i=1,min(flen,Nbath)
                read(unit,*)(&
                     dmft_bath_%e(ispin,1,i),&
                     dmft_bath_%d(ispin,1,i),&
                     (&
                     dmft_bath_%v(ispin,iorb,i),&
                     iorb=1,Norb),&
                     ispin=1,Nspin)
             enddo
          case ("nonsu2")
             do i=1,min(flen,Nbath)
                read(unit,*)(&
                     dmft_bath_%e(ispin,1,i),&
                     (&
                     dmft_bath_%v(ispin,iorb,i),&
                     dmft_bath_%u(ispin,iorb,i),&
                     iorb=1,Norb),&
                     ispin=1,Nspin)
             enddo
          end select
          !
       case ('replica')
          read(unit,*)
          !
          read(unit,*)dmft_bath%Nbasis
          do i=1,Nbath
             read(unit,*)dmft_bath_%item(i)%v,&
                  (dmft_bath_%item(i)%lambda(io),io=1,dmft_bath_%Nbasis)
          enddo
          !
       end select
       close(unit)
    endif
  end subroutine init_dmft_bath



  !+-------------------------------------------------------------------+
  !PURPOSE  : write out the bath to a given unit with 
  ! the following column formatting: 
  ! [(Ek_iorb,Vk_iorb)_iorb=1,Norb]_ispin=1,Nspin
  !+-------------------------------------------------------------------+
  subroutine write_dmft_bath(dmft_bath_,unit)
    type(effective_bath) :: dmft_bath_
    integer,optional     :: unit
    integer              :: unit_
    integer              :: i,Nsym
    integer              :: io,jo,iorb,ispin,isym
    real(8)              :: hybr_aux
    complex(8)           :: ho(Nspin*Norb,Nspin*Norb)
    character(len=64)    :: string_fmt,string_fmt_first
    !
#ifdef _DEBUG
    if(ed_verbose>1)write(Logfile,"(A)")"DEBUG write_dmft_bath"
#endif
    unit_=LOGfile;if(present(unit))unit_=unit
    if(.not.dmft_bath_%status)stop "write_dmft_bath error: bath not allocated"
    select case(bath_type)
    case default
       !
       select case(ed_mode)
       case default
          write(unit_,"(90(A21,1X))")&
               ((&
               "#Ek_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)),&
               "Vk_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)),&
               iorb=1,Norb),ispin=1,Nspin)
          do i=1,Nbath
             write(unit_,"(90(ES21.12,1X))")((&
                  dmft_bath_%e(ispin,iorb,i),&
                  dmft_bath_%v(ispin,iorb,i),&
                  iorb=1,Norb),ispin=1,Nspin)
          enddo
       case ("superc")
          write(unit_,"(90(A21,1X))")&
               ((&
               "#Ek_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)),&
               "Dk_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)) ,&
               "Vk_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)),&
               iorb=1,Norb),ispin=1,Nspin)
          do i=1,Nbath
             write(unit_,"(90(ES21.12,1X))")((&
                  dmft_bath_%e(ispin,iorb,i),&
                  dmft_bath_%d(ispin,iorb,i),&
                  dmft_bath_%v(ispin,iorb,i),&
                  iorb=1,Norb),ispin=1,Nspin)
          enddo
       case ("nonsu2")
          write(unit_,"(90(A21,1X))")&
               ((&
               "#Ek_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)),&
               "Vak_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)),&
               "Vbk_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)),&
               iorb=1,Norb), ispin=1,Nspin)
          do i=1,Nbath
             write(unit,"(90(ES21.12,1X))")((&
                  dmft_bath_%e(ispin,iorb,i),&
                  dmft_bath_%v(ispin,iorb,i),&
                  dmft_bath_%u(ispin,iorb,i),&
                  iorb=1,Norb),ispin=1,Nspin)
          enddo
       end select
       !
    case('hybrid')
       !
       select case(ed_mode)
       case default
          write(unit_,"(90(A21,1X))")(&
               "#Ek_s"//reg(txtfy(ispin)),&
               ("Vk_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)),iorb=1,Norb),&
               ispin=1,Nspin)
          do i=1,Nbath
             write(unit_,"(90(ES21.12,1X))")(&
                  dmft_bath_%e(ispin,1,i),&
                  (dmft_bath_%v(ispin,iorb,i),iorb=1,Norb),&
                  ispin=1,Nspin)
          enddo
       case ("superc")
          write(unit_,"(90(A21,1X))")(&
               "#Ek_s"//reg(txtfy(ispin)),&
               "Dk_s"//reg(txtfy(ispin)) ,&
               ("Vk_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)),iorb=1,Norb),&
               ispin=1,Nspin)
          do i=1,Nbath
             write(unit_,"(90(ES21.12,1X))")(&
                  dmft_bath_%e(ispin,1,i),&
                  dmft_bath_%d(ispin,1,i),&
                  (dmft_bath_%v(ispin,iorb,i),iorb=1,Norb),&
                  ispin=1,Nspin)
          enddo
       case ("nonsu2")
          write(unit_,"(90(A21,1X))")(&
               "#Ek_s"//reg(txtfy(ispin)),&
               (&
               "Vak_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)),&
               "Vbk_l"//reg(txtfy(iorb))//"_s"//reg(txtfy(ispin)),&
               iorb=1,Norb),&
               ispin=1,Nspin)
          do i=1,Nbath
             write(unit_,"(90(ES21.12,1X))")(&
                  dmft_bath_%e(ispin,1,i),    &
                  (dmft_bath_%v(ispin,iorb,i),dmft_bath_%u(ispin,iorb,i),iorb=1,Norb),&
                  ispin=1,Nspin)
          enddo
       end select
       !
    case ('replica')
       !
       string_fmt      ="("//str(Nspin*Norb)//"(A1,F5.2,A1,F5.2,A1,2x))" 
       !
       write(unit_,"(90(A21,1X))")"#V_i",("Lambda_i"//reg(txtfy(io)),io=1,dmft_bath_%Nbasis)
       write(unit_,"(I3)")dmft_bath_%Nbasis
       do i=1,Nbath
          write(unit_,"(90(ES21.12,1X))")dmft_bath_%item(i)%v,&
               (dmft_bath_%item(i)%lambda(io),io=1,dmft_bath_%Nbasis)
       enddo
       !
       if(unit_/=LOGfile)then
          write(unit_,*)""
          do isym=1,size(Hreplica_basis)
             Ho = nn2so_reshape(Hreplica_basis(isym)%O,nspin,norb)
             do io=1,Nspin*Norb
                write(unit,string_fmt)&
                     ('(',dreal(Ho(io,jo)),',',dimag(Ho(io,jo)),')',jo =1,Nspin*Norb)
             enddo
             write(unit,*)""
          enddo
       endif
    end select
  end subroutine write_dmft_bath






  !+-------------------------------------------------------------------+
  !PURPOSE  : save the bath to a given file using the write bath
  ! procedure and formatting: 
  !+-------------------------------------------------------------------+
  subroutine save_dmft_bath(dmft_bath_,file,used)
    type(effective_bath)      :: dmft_bath_
    character(len=*),optional :: file
    character(len=256)        :: file_
    logical,optional          :: used
    logical                   :: used_
    character(len=16)         :: extension
    integer                   :: unit_
#ifdef _DEBUG
    if(ed_verbose>1)write(Logfile,"(A)")"DEBUG save_dmft_bath"
#endif
    if(.not.dmft_bath_%status)stop "save_dmft_bath error: bath is not allocated"
    used_=.false.;if(present(used))used_=used
    extension=".restart";if(used_)extension=".used"
    file_=str(str(Hfile)//str(ed_file_suffix)//str(extension))
    if(present(file))file_=str(file)
    unit_=free_unit()
    open(unit_,file=str(file_))
    call write_dmft_bath(dmft_bath_,unit_)
    close(unit_)
  end subroutine save_dmft_bath




  !+-------------------------------------------------------------------+
  !PURPOSE  : set the bath components from a given user provided 
  ! bath-array 
  !+-------------------------------------------------------------------+
  subroutine set_dmft_bath(bath_,dmft_bath_)
    real(8),dimension(:)   :: bath_
    type(effective_bath)   :: dmft_bath_
    integer                :: stride,io,jo,i
    integer                :: iorb,ispin,jorb,jspin,ibath
    logical                :: check
    !
#ifdef _DEBUG
    if(ed_verbose>1)write(Logfile,"(A)")"DEBUG set_dmft_bath: dmft_bath <- user_bath"
#endif
    if(.not.dmft_bath_%status)stop "set_dmft_bath error: bath not allocated"
    check = check_bath_dimension(bath_)
    if(.not.check)stop "set_dmft_bath error: wrong bath dimensions"
    !
    select case(bath_type)
    case default
       !
       select case(ed_mode)
          !
       case default
          stride = 0
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   dmft_bath_%e(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
          stride = Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   dmft_bath_%v(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
          !
       case ("superc")
          stride = 0
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   dmft_bath_%e(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
          stride = Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   dmft_bath_%d(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
          stride = 2*Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   dmft_bath_%v(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
          !
       case("nonsu2")
          stride = 0
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   dmft_bath_%e(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
          stride = Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   dmft_bath_%v(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
          stride = 2*Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   dmft_bath_%u(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
       end select
       !
       !
    case ('hybrid')
       !
       select case(ed_mode)
       case default
          stride = 0
          do ispin=1,Nspin
             do i=1,Nbath
                io = stride + i + (ispin-1)*Nbath
                dmft_bath_%e(ispin,1,i) = bath_(io)
             enddo
          enddo
          stride = Nspin*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Norb*Nbath
                   dmft_bath_%v(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
          !
       case ("superc")
          stride = 0
          do ispin=1,Nspin
             do i=1,Nbath
                io = stride + i + (ispin-1)*Nbath
                dmft_bath_%e(ispin,1,i) = bath_(io)
             enddo
          enddo
          stride = Nspin*Nbath
          do ispin=1,Nspin
             do i=1,Nbath
                io = stride + i + (ispin-1)*Nbath
                dmft_bath_%d(ispin,1,i) = bath_(io)
             enddo
          enddo
          stride = 2*Nspin*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Norb*Nbath
                   dmft_bath_%v(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
          !
       case("nonsu2")
          stride = 0
          do ispin=1,Nspin
             do i=1,Nbath
                io = stride + i + (ispin-1)*Nbath
                dmft_bath_%e(ispin,1,i) = bath_(io)
             enddo
          enddo
          stride = Nspin*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Norb*Nbath
                   dmft_bath_%v(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
          stride = Nspin*Nbath + Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Norb*Nbath
                   dmft_bath_%u(ispin,iorb,i) = bath_(io)
                enddo
             enddo
          enddo
       end select
       !
       !
    case ('replica')
       !
       stride = 1
       !Get Nbasis
       dmft_bath_%Nbasis = NINT(bath_(stride))
       !get Lambdas
       do ibath=1,Nbath
          stride = stride + 1
          dmft_bath_%item(ibath)%v = bath_(stride)
          dmft_bath_%item(ibath)%lambda=bath_(stride+1 :stride+dmft_bath_%Nbasis)
          stride=stride+dmft_bath_%Nbasis
       enddo
    end select
  end subroutine set_dmft_bath



  !+-------------------------------------------------------------------+
  !PURPOSE  : copy the bath components back to a 1-dim array 
  !+-------------------------------------------------------------------+
  subroutine get_dmft_bath(dmft_bath_,bath_)
    type(effective_bath)   :: dmft_bath_
    real(8),dimension(:)   :: bath_
    real(8)                :: hrep_aux(Nspin*Norb,Nspin*Norb)
    integer                :: stride,io,jo,i
    integer                :: iorb,ispin,jorb,jspin,ibath,maxspin
    logical                :: check
#ifdef _DEBUG
    if(ed_verbose>1)write(Logfile,"(A)")"DEBUG get_dmft_bath: dmft_bath -> user_bath"
#endif
    if(.not.dmft_bath_%status)stop "get_dmft_bath error: bath not allocated"
    check=check_bath_dimension(bath_)
    if(.not.check)stop "get_dmft_bath error: wrong bath dimensions"
    !
    bath_ = 0d0
    !
    select case(bath_type)
    case default
       !
       select case(ed_mode)
       case default
          stride = 0
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   bath_(io) = dmft_bath_%e(ispin,iorb,i) 
                enddo
             enddo
          enddo
          stride = Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   bath_(io) = dmft_bath_%v(ispin,iorb,i)
                enddo
             enddo
          enddo
          !
       case ("superc")
          stride = 0
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   bath_(io) = dmft_bath_%e(ispin,iorb,i)
                enddo
             enddo
          enddo
          stride = Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   bath_(io) =  dmft_bath_%d(ispin,iorb,i)
                enddo
             enddo
          enddo
          stride = 2*Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   bath_(io) =  dmft_bath_%v(ispin,iorb,i)
                enddo
             enddo
          enddo
          !
       case("nonsu2")
          stride = 0
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   bath_(io) = dmft_bath_%e(ispin,iorb,i)
                enddo
             enddo
          enddo
          stride = Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   bath_(io) = dmft_bath_%v(ispin,iorb,i)
                enddo
             enddo
          enddo
          stride = 2*Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Nbath*Norb
                   bath_(io) = dmft_bath_%u(ispin,iorb,i)
                enddo
             enddo
          enddo
       end select
       !
    case ('hybrid')
       !
       select case(ed_mode)
       case default
          stride = 0
          do ispin=1,Nspin
             do i=1,Nbath
                io = stride + i + (ispin-1)*Nbath
                bath_(io) =  dmft_bath_%e(ispin,1,i)
             enddo
          enddo
          stride = Nspin*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Norb*Nbath
                   bath_(io) =  dmft_bath_%v(ispin,iorb,i)
                enddo
             enddo
          enddo
          !
       case ("superc")
          stride = 0
          do ispin=1,Nspin
             do i=1,Nbath
                io = stride + i + (ispin-1)*Nbath
                bath_(io) =  dmft_bath_%e(ispin,1,i)
             enddo
          enddo
          stride = Nspin*Nbath
          do ispin=1,Nspin
             do i=1,Nbath
                io = stride + i + (ispin-1)*Nbath
                bath_(io) =  dmft_bath_%d(ispin,1,i)
             enddo
          enddo
          stride = 2*Nspin*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Norb*Nbath
                   bath_(io) =  dmft_bath_%v(ispin,iorb,i)
                enddo
             enddo
          enddo
          !
       case("nonsu2")
          stride = 0
          do ispin=1,Nspin
             do i=1,Nbath
                io = stride + i + (ispin-1)*Nbath
                bath_(io) = dmft_bath_%e(ispin,1,i) 
             enddo
          enddo
          stride = Nspin*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Norb*Nbath
                   bath_(io) = dmft_bath_%v(ispin,iorb,i)
                enddo
             enddo
          enddo
          stride = Nspin*Nbath + Nspin*Norb*Nbath
          do ispin=1,Nspin
             do iorb=1,Norb
                do i=1,Nbath
                   io = stride + i + (iorb-1)*Nbath + (ispin-1)*Norb*Nbath
                   bath_(io) = dmft_bath_%u(ispin,iorb,i)
                enddo
             enddo
          enddo
       end select
       !
       !
    case ('replica')
       !
       stride = 1
       bath_(stride)=dmft_bath_%Nbasis
       do ibath=1,Nbath
          stride = stride + 1
          bath_(stride)=dmft_bath_%item(ibath)%v
          bath_(stride+1 : stride+dmft_bath_%Nbasis)=dmft_bath_%item(ibath)%lambda
          stride=stride+dmft_bath_%Nbasis
       enddo
    end select
  end subroutine get_dmft_bath





  !##################################################################
  !
  !     W_hyb PROCEDURES
  !
  !##################################################################
  !+-----------------------------------------------------------------------------+!
  !PURPOSE: build up the all-spin hybridization matrix W_{ss`}
  !+-----------------------------------------------------------------------------+!
  function get_Whyb_matrix_1orb(v,u) result(w)
    real(8),dimension(Nspin,Nbath)       :: v,u
    real(8),dimension(Nspin,Nspin,Nbath) :: w
    integer                              :: ispin
    !
    ! if(ed_para)then
    !    do ispin=1,Nspin
    !       w(ispin,ispin,:) = v(1,:)
    !    enddo
    !    w(1,Nspin,:) = u(1,:)
    !    w(Nspin,1,:) = u(1,:)
    ! else
    do ispin=1,Nspin
       w(ispin,ispin,:) = v(ispin,:)
    enddo
    w(1,Nspin,:) = u(1,:)
    w(Nspin,1,:) = u(2,:)
    ! endif
    !
  end function get_Whyb_matrix_1orb

  function get_Whyb_matrix_Aorb(v,u) result(w)
    real(8),dimension(Nspin,Norb,Nbath)       :: v,u
    real(8),dimension(Nspin,Nspin,Norb,Nbath) :: w
    integer                                   :: ispin
    !
    ! if(ed_para)then
    !    do ispin=1,Nspin
    !       w(ispin,ispin,:,:) = v(1,:,:)
    !    enddo
    !    w(1,Nspin,:,:) = u(1,:,:)
    !    w(Nspin,1,:,:) = u(1,:,:)
    ! else
    do ispin=1,Nspin
       w(ispin,ispin,:,:) = v(ispin,:,:)
    enddo
    w(1,Nspin,:,:) = u(1,:,:)
    w(Nspin,1,:,:) = u(2,:,:)
    ! endif
    !
  end function get_Whyb_matrix_Aorb

  function get_Whyb_matrix_dmft_bath(dmft_bath_) result(w)
    type(effective_bath)                      :: dmft_bath_
    real(8),dimension(Nspin,Nspin,Norb,Nbath) :: w
    integer                                   :: ispin
    !
    ! if(ed_para)then
    !    do ispin=1,Nspin
    !       w(ispin,ispin,:,:) = dmft_bath_%v(1,:,:)
    !    enddo
    !    w(1,Nspin,:,:) = dmft_bath_%u(1,:,:)
    !    w(Nspin,1,:,:) = dmft_bath_%u(1,:,:)
    ! else
    do ispin=1,Nspin
       w(ispin,ispin,:,:) = dmft_bath_%v(ispin,:,:)
    enddo
    w(1,Nspin,:,:) = dmft_bath_%u(1,:,:)
    w(Nspin,1,:,:) = dmft_bath_%u(2,:,:)
    ! endif
    !
  end function get_Whyb_matrix_dmft_bath




























  !##################################################################
  !
  !     H_REPLICA ROUTINES:
  !
  !##################################################################
  !-------------------------------------------------------------------!
  ! PURPOSE: INITIALIZE INTERNAL Hreplica STRUCTURES
  !-------------------------------------------------------------------!

  !allocate GLOBAL basis for H (used for impHloc and bath) and vectors coefficient
  subroutine allocate_hreplica(N)
    integer          :: N
    integer          :: isym
    !
#ifdef _DEBUG
    if(ed_verbose>3)write(Logfile,"(A)")"DEBUG allocate_Hreplica"
#endif
    if(allocated(Hreplica_basis))deallocate(Hreplica_basis)
    if(allocated(Hreplica_lambda))deallocate(Hreplica_lambda)
    !
    allocate(Hreplica_basis(N))
    allocate(Hreplica_lambda(N))
    do isym=1,N
       allocate(Hreplica_basis(isym)%O(Nspin,Nspin,Norb,Norb))
       Hreplica_basis(isym)%O=0d0
       Hreplica_lambda(isym)=0d0
    enddo
    Hreplica_status=.true.
  end subroutine allocate_hreplica


  !deallocate GLOBAL basis for H (used for impHloc and bath) and vectors coefficient
  subroutine deallocate_hreplica()
    integer              :: isym
    !
#ifdef _DEBUG
    if(ed_verbose>3)write(Logfile,"(A)")"DEBUG deallocate_Hreplica"
#endif
    do isym=1,size(Hreplica_basis)
       deallocate(Hreplica_basis(isym)%O)
    enddo
    deallocate(Hreplica_basis)
    deallocate(Hreplica_lambda)
    Hreplica_status=.false.
  end subroutine deallocate_hreplica


  !+------------------------------------------------------------------+
  !PURPOSE  : Set Hreplica from user defined Hloc
  !1: [Nspin,Nspin,Norb,Norb]
  !2: [Nspin*Norb,Nspin*Norb]
  !+------------------------------------------------------------------+
  subroutine init_Hreplica_direct_nn(Hloc)
    integer                                     :: ispin,jspin,iorb,jorb,counter,io,jo,Nsym
    complex(8),dimension(Nspin,Nspin,Norb,Norb) :: Hloc
    logical(8),dimension(Nspin,Nspin,Norb,Norb) :: Hmask
    !
#ifdef _DEBUG
    if(ed_verbose>3)write(Logfile,"(A)")"DEBUG init_Hreplica_direct_nn: from Hloc[:,:,:,:]"
#endif
    !
    Hmask=.false.
    !
    counter=0
    do ispin=1,Nspin
       do jspin=1,Nspin
          do iorb=1,Norb
             do jorb=1,Norb
                io=index_stride_so(ispin,iorb)
                jo=index_stride_so(jspin,jorb)
                if(io > jo )cycle
                if(Hloc(ispin,jspin,iorb,jorb)/=zero)counter=counter+1
             enddo
          enddo
       enddo
    enddo
    !
    call allocate_hreplica(counter)
    !
    counter=0
    do ispin=1,Nspin
       do jspin=1,Nspin
          do iorb=1,Norb
             do jorb=1,Norb
                io=index_stride_so(ispin,iorb)
                jo=index_stride_so(jspin,jorb)
                if(io > jo )cycle
                if(Hloc(ispin,jspin,iorb,jorb)/=zero)then
                   counter=counter+1
                   Hreplica_basis(counter)%O(ispin,jspin,iorb,jorb)=1d0
                   Hreplica_basis(counter)%O(ispin,jspin,jorb,iorb)=1d0
                   Hreplica_lambda(counter)=Hloc(ispin,ispin,iorb,jorb)
                endif
             enddo
          enddo
       enddo
    enddo
    !
  end subroutine init_Hreplica_direct_nn

  subroutine init_Hreplica_direct_so(Hloc)
    complex(8),dimension(Nspin*Norb,Nspin*Norb) :: Hloc
#ifdef _DEBUG
    if(ed_verbose>3)write(Logfile,"(A)")"DEBUG init_Hreplica_direct_so: from Hloc[:,:]"
#endif
    call init_Hreplica_direct_nn(so2nn_reshape(Hloc,Nspin,Norb))
  end subroutine init_Hreplica_direct_so


  subroutine init_Hreplica_symmetries_site(Hvec,lambdavec)
    complex(8),dimension(:,:,:,:,:) :: Hvec
    real(8),dimension(:)            :: lambdavec
    integer                         :: isym,N
    !
#ifdef _DEBUG
    if(ed_verbose>3)write(Logfile,"(A)")"DEBUG init_Hreplica_direct_nn: from {[Hs,Lam]}_b"
#endif
    !
    N=size(lambdavec)
    call assert_shape(Hvec,[Nspin,Nspin,Norb,Norb,N],"init_Hreplica_symmetries","Hvec")
    !
    call allocate_hreplica(N)
    !
    do isym=1,N
       Hreplica_lambda(isym)  = lambdavec(isym)
       Hreplica_basis(isym)%O = Hvec(:,:,:,:,isym)
    enddo
    !
    if(ed_verbose>2)call print_hloc(Hreplica_build(Hreplica_lambda))
  end subroutine init_Hreplica_symmetries_site



  subroutine init_Hreplica_symmetries_lattice(Hvec,lambdavec)
    complex(8),dimension(:,:,:,:,:) :: Hvec
    real(8),dimension(:,:)          :: lambdavec ![Nlat,Nsym]
    integer                         :: isym,ilat,N,Nlat
    !
#ifdef _DEBUG
    if(ed_verbose>3)write(Logfile,"(A)")"DEBUG init_Hreplica_direct_nn: from ({[Hs,Lam]}_b)_site"
#endif
    !
    Nlat=size(lambdavec,1)
    N   =size(lambdavec,2)
    call assert_shape(Hvec,[Nspin,Nspin,Norb,Norb,N],"init_Hreplica_symmetries","Hvec")
    !
    if(allocated(Hreplica_lambda_ineq))deallocate(Hreplica_lambda_ineq)
    allocate(Hreplica_lambda_ineq(Nlat,N))
    call allocate_hreplica(N)
    !
    do isym=1,N
       Hreplica_lambda_ineq(:,isym)  = lambdavec(:,isym)
       Hreplica_basis(isym)%O = Hvec(:,:,:,:,isym)
    enddo
    !
    if(ed_verbose>2)then
       do ilat=1,Nlat
          call print_hloc(Hreplica_build(Hreplica_lambda_ineq(ilat,:)))
       enddo
    endif
  end subroutine init_Hreplica_symmetries_lattice


























  !##################################################################
  !
  !     AUX FUNCTIONS:
  !
  !##################################################################
  subroutine Hreplica_site(site)
    integer :: site
    if(site<1.OR.site>size(Hreplica_lambda_ineq,1))stop "ERROR Hreplica_site: site not in [1,Nlat]"
    if(.not.allocated(Hreplica_lambda_ineq))stop "ERROR Hreplica_site: Hreplica_lambda_ineq not allocated"
    Hreplica_lambda(:)  = Hreplica_lambda_ineq(site,:)
  end subroutine Hreplica_site


  !reconstruct [Nspin,Nspin,Norb,Norb] hamiltonian from basis expansion given [lambda]
  function Hreplica_build(lambdavec) result(H)
    real(8),dimension(:)                        :: lambdavec
    integer                                     :: isym
    complex(8),dimension(Nspin,Nspin,Norb,Norb) :: H
    !
    if(.not.Hreplica_status)STOP "ERROR Hreplica_build: Hreplica_basis is not setup"
    if(size(lambdavec)/=size(Hreplica_basis)) STOP "ERROR Hreplica_build: Wrong coefficient vector size"
    H=zero
    do isym=1,size(lambdavec)
       H=H+lambdavec(isym)*Hreplica_basis(isym)%O
    enddo
  end function Hreplica_build



  !+-------------------------------------------------------------------+
  !PURPOSE  : Create bath mask
  !+-------------------------------------------------------------------+
  function Hreplica_mask(wdiag,uplo) result(Hmask)
    logical,optional                            :: wdiag,uplo
    logical                                     :: wdiag_,uplo_
    complex(8),dimension(Nspin,Nspin,Norb,Norb) :: Hloc
    logical,dimension(Nspin,Nspin,Norb,Norb)    :: Hmask
    integer                                     :: iorb,jorb,ispin,jspin,io,jo
    !
    wdiag_=.false.;if(present(wdiag))wdiag_=wdiag
    uplo_ =.false.;if(present(uplo))  uplo_=uplo
    !
    Hloc = Hreplica_build(Hreplica_lambda)
    Hmask=.false.
    where(abs(Hloc)>1d-6)Hmask=.true.
    !
    !
    if(wdiag_)then
       do ispin=1,Nspin
          do iorb=1,Norb
             Hmask(ispin,ispin,iorb,iorb)=.true.
          enddo
       enddo
    endif
    !
    if(uplo_)then
       do ispin=1,Nspin
          do jspin=1,Nspin
             do iorb=1,Norb
                do jorb=1,Norb
                   io = index_stride_so(ispin,iorb)
                   jo = index_stride_so(jspin,jorb)
                   if(io>jo)Hmask(ispin,jspin,iorb,jorb)=.false.
                enddo
             enddo
          enddo
       enddo
    endif
    !
  end function Hreplica_mask




  !+-------------------------------------------------------------------+
  !PURPOSE  : Check if a matrix is the identity
  !+-------------------------------------------------------------------+
  function is_identity_nn(mnnn) result(flag)
    complex(8),dimension(nspin,nspin,norb,norb) :: mnnn
    real(8),dimension(nspin*norb,nspin*norb) :: mtmp
    integer                                  :: i,j
    logical                                  :: flag
    !
    flag=.true.
    !
    mtmp=nn2so_reshape(mnnn,nspin,norb)
    !
    do i=1,Nspin*Norb-1
       if((mtmp(i,i).ne.mtmp(i+1,i+1)).or.(mtmp(i,i).lt.1.d-6))flag=.false.
    enddo
    !
    do i=1,Nspin*Norb
       do j=1,Nspin*Norb
          if((i.ne.j).and.(mtmp(i,j).gt.1.d-6))flag=.false.
       enddo
    enddo
    !
  end function is_identity_nn

  function is_identity_so(mlso) result(flag)
    complex(8),dimension(nspin*norb,nspin*norb) :: mlso
    real(8),dimension(nspin*norb,nspin*norb) :: mtmp
    integer                                  :: i,j
    logical                                  :: flag
    !
    flag=.true.
    !
    mtmp=mlso
    !
    do i=1,Nspin*Norb-1
       if((mtmp(i,i).ne.mtmp(i+1,i+1)).or.(mtmp(i,i).lt.1.d-6))flag=.false.
    enddo
    !
    do i=1,Nspin*Norb
       do j=1,Nspin*Norb
          if((i.ne.j).and.(mtmp(i,j).gt.1.d-6))flag=.false.
       enddo
    enddo
    !
  end function is_identity_so



  !+-------------------------------------------------------------------+
  !PURPOSE  : Check if a matrix is diagonal
  !+-------------------------------------------------------------------+
  function is_diagonal_nn(mnnn) result(flag)
    complex(8),dimension(nspin,nspin,norb,norb) :: mnnn
    complex(8),dimension(nspin*norb,nspin*norb) :: mtmp
    integer                                     :: i,j
    logical                                     :: flag
    !
    flag=.true.
    !
    mtmp=abs((nn2so_reshape(mnnn,nspin,norb)))
    !
    do i=1,Nspin*Norb
       do j=1,Nspin*Norb
          if((i.ne.j).and.(abs(mtmp(i,j)).gt.1.d-6))flag=.false.
       enddo
    enddo
    !
  end function is_diagonal_nn

  function is_diagonal_so(mlso) result(flag)
    complex(8),dimension(Nspin*Norb,Nspin*Norb) :: mlso
    complex(8),dimension(Nspin*Norb,Nspin*Norb) :: mtmp
    integer                                     :: i,j
    logical                                     :: flag
    !
    flag=.true.
    !
    mtmp=abs((mlso))
    !
    do i=1,Nspin*Norb
       do j=1,Nspin*Norb
          if((i.ne.j).and.(abs(mtmp(i,j)).gt.1.d-6))flag=.false.
       enddo
    enddo
    !
  end function is_diagonal_so










END MODULE ED_BATH
