












MODULE module_mp_wsm6
!
   IMPLICIT NONE
!
   REAL, PARAMETER, PUBLIC :: dtcldcr     = 120. ! maximum time step for minor loops
   REAL, PARAMETER, PUBLIC :: n0r = 8.e6         ! intercept parameter rain
   REAL, PARAMETER, PUBLIC :: n0g = 4.e6         ! intercept parameter graupel
   REAL, PARAMETER, PUBLIC :: avtr = 841.9       ! a constant for terminal velocity of rain
   REAL, PARAMETER, PUBLIC :: bvtr = 0.8         ! a constant for terminal velocity of rain
   REAL, PARAMETER, PUBLIC :: r0 = .8e-5         ! 8 microm  in contrast to 10 micro m
   REAL, PARAMETER, PUBLIC :: peaut = .55        ! collection efficiency
   REAL, PARAMETER, PUBLIC :: xncr = 3.e8        ! maritime cloud in contrast to 3.e8 in tc80
   REAL, PARAMETER, PUBLIC :: xmyu = 1.718e-5    ! the dynamic viscosity kgm-1s-1
   REAL, PARAMETER, PUBLIC :: avts = 11.72       ! a constant for terminal velocity of snow
   REAL, PARAMETER, PUBLIC :: bvts = .41         ! a constant for terminal velocity of snow
   REAL, PARAMETER, PUBLIC :: avtg = 330.        ! a constant for terminal velocity of graupel
   REAL, PARAMETER, PUBLIC :: bvtg = 0.8         ! a constant for terminal velocity of graupel
   REAL, PARAMETER, PUBLIC :: deng = 500.        ! density of graupel
   REAL, PARAMETER, PUBLIC :: n0smax =  1.e11    ! maximum n0s (t=-90C unlimited)
   REAL, PARAMETER, PUBLIC :: lamdarmax = 8.e4   ! limited maximum value for slope parameter of rain
   REAL, PARAMETER, PUBLIC :: lamdasmax = 1.e5   ! limited maximum value for slope parameter of snow
   REAL, PARAMETER, PUBLIC :: lamdagmax = 6.e4   ! limited maximum value for slope parameter of graupel
   REAL, PARAMETER, PUBLIC :: dicon = 11.9       ! constant for the cloud-ice diamter
   REAL, PARAMETER, PUBLIC :: dimax = 500.e-6    ! limited maximum value for the cloud-ice diamter
   REAL, PARAMETER, PUBLIC :: n0s = 2.e6         ! temperature dependent intercept parameter snow
   REAL, PARAMETER, PUBLIC :: alpha = .12        ! .122 exponen factor for n0s
   REAL, PARAMETER, PUBLIC :: pfrz1 = 100.       ! constant in Biggs freezing
   REAL, PARAMETER, PUBLIC :: pfrz2 = 0.66       ! constant in Biggs freezing
   REAL, PARAMETER, PUBLIC :: qcrmin = 1.e-9     ! minimun values for qr, qs, and qg
   REAL, PARAMETER, PUBLIC :: eacrc = 1.0        ! Snow/cloud-water collection efficiency
   REAL, PARAMETER, PUBLIC :: dens  =  100.0     ! Density of snow
   REAL, PARAMETER, PUBLIC :: qs0   =  6.e-4     ! threshold amount for aggretion to occur
   REAL, SAVE ::                                      &
             qc0, qck1,bvtr1,bvtr2,bvtr3,bvtr4,g1pbr, &
             g3pbr,g4pbr,g5pbro2,pvtr,eacrr,pacrr,    &
             bvtr6,g6pbr,                             &
             precr1,precr2,roqimax,bvts1,             &
             bvts2,bvts3,bvts4,g1pbs,g3pbs,g4pbs,     &
             g5pbso2,pvts,pacrs,precs1,precs2,pidn0r, &
             pidn0s,xlv1,pacrc,pi,                    &
             bvtg1,bvtg2,bvtg3,bvtg4,g1pbg,           &
             g3pbg,g4pbg,g5pbgo2,pvtg,pacrg,          &
             precg1,precg2,pidn0g,                    &
             rslopermax,rslopesmax,rslopegmax,        &
             rsloperbmax,rslopesbmax,rslopegbmax,     &
             rsloper2max,rslopes2max,rslopeg2max,     &
             rsloper3max,rslopes3max,rslopeg3max
CONTAINS
!===================================================================
!
!===================================================================
!
  SUBROUTINE wsm62D(t, q                                          &   
                   ,qci, qrs, den, p, delz                        &
                   ,delt,g, cpd, cpv, rd, rv, t0c                 &
                   ,ep1, ep2, qmin                                &
                   ,XLS, XLV0, XLF0, den0, denr                   &
                   ,cliq,cice,psat                                &
                   ,lat                                           &
                   ,rain,rainncv                                  &
                   ,sr                                            &
                   ,ids,ide, jds,jde, kds,kde                     &
                   ,ims,ime, jms,jme, kms,kme                     &
                   ,its,ite, jts,jte, kts,kte                     &
                   ,snow,snowncv                                  &
                   ,graupel,graupelncv                            &
                                                                  )
!-------------------------------------------------------------------
  IMPLICIT NONE
!-------------------------------------------------------------------
!
!  This code is a 6-class GRAUPEL phase microphyiscs scheme (WSM6) of the 
!  Single-Moment MicroPhyiscs (WSMMP). The WSMMP assumes that ice nuclei
!  number concentration is a function of temperature, and seperate assumption
!  is developed, in which ice crystal number concentration is a function
!  of ice amount. A theoretical background of the ice-microphysics and related
!  processes in the WSMMPs are described in Hong et al. (2004).
!  All production terms in the WSM6 scheme are described in Hong and Lim (2006).
!  All units are in m.k.s. and source/sink terms in kgkg-1s-1.
!
!  WSM6 cloud scheme
!
!  Coded by Song-You Hong and Jeong-Ock Jade Lim (Yonsei Univ.)
!           Summer 2003
!
!  Implemented by Song-You Hong (Yonsei Univ.) and Jimy Dudhia (NCAR)
!           Summer 2004
!
!  History :  semi-lagrangian scheme sedimentation(JH), and clean up
!             Hong, August 2009
!
!  Reference) Hong, Dudhia, Chen (HDC, 2004) Mon. Wea. Rev.
!             Hong and Lim (HL, 2006) J. Korean Meteor. Soc.
!             Dudhia, Hong and Lim (DHL, 2008) J. Meteor. Soc. Japan
!             Lin, Farley, Orville (LFO, 1983) J. Appl. Meteor.
!             Rutledge, Hobbs (RH83, 1983) J. Atmos. Sci.
!             Rutledge, Hobbs (RH84, 1984) J. Atmos. Sci.
!             Juang and Hong (JH, 2010) Mon. Wea. Rev.
!
  INTEGER,      INTENT(IN   )    ::   ids,ide, jds,jde, kds,kde , &
                                      ims,ime, jms,jme, kms,kme , &
                                      its,ite, jts,jte, kts,kte,  &
                                      lat
  REAL, DIMENSION( 1:2 , 1:32 ),                           &
        INTENT(INOUT) ::                                          &
                                                               t
  REAL, DIMENSION( 1:2 , 1:32, 2 ),                        &
        INTENT(INOUT) ::                                          &
                                                             qci
  REAL, DIMENSION( 1:2 , 1:32, 3 ),                        &
        INTENT(INOUT) ::                                          &
                                                             qrs
  REAL, DIMENSION( 1:2 , 1:33 ),                           &
        INTENT(INOUT) ::                                          &
                                                               q
  REAL, DIMENSION( 1:2 , 1:33 ),                           &
        INTENT(IN   ) ::                                          &
                                                             den, &
                                                               p, &
                                                            delz
  REAL, INTENT(IN   ) ::                                    delt, &
                                                               g, &
                                                             cpd, &
                                                             cpv, &
                                                             t0c, &
                                                            den0, &
                                                              rd, &
                                                              rv, &
                                                             ep1, &
                                                             ep2, &
                                                            qmin, &
                                                             XLS, &
                                                            XLV0, &
                                                            XLF0, &
                                                            cliq, &
                                                            cice, &
                                                            psat, &
                                                            denr
  REAL, DIMENSION( 1:2 ),                                     &
        INTENT(INOUT) ::                                    rain, &
                                                         rainncv, &
                                                              sr
  REAL, DIMENSION( 1:2, jms:jme ), OPTIONAL,                  &
        INTENT(INOUT) ::                                    snow, &
                                                         snowncv
  REAL, DIMENSION( 1:2, jms:jme ), OPTIONAL,                  &
        INTENT(INOUT) ::                                 graupel, &
                                                      graupelncv
! LOCAL VAR
  REAL, DIMENSION( 1:2 , 1:32 , 3) ::                      &
                                                              rh, &
                                                              qs, &
                                                          rslope, &
                                                         rslope2, &
                                                         rslope3, &
                                                         rslopeb, &
                                                         qrs_tmp, & 
                                                            falk, &
                                                            fall, &
                                                           work1
  REAL, DIMENSION( 1:2 , 1:32 ) ::                         &
                                                           fallc, &
                                                           falkc, &
                                                          work1c, &
                                                          work2c, &
                                                           workr, &
                                                           worka
  REAL, DIMENSION( 1:2 , 1:32 ) ::                         &
                                                         den_tmp, &
                                                        delz_tmp
  REAL, DIMENSION( 1:2 , 1:32 ) ::                         &
                                                           pigen, &
                                                           pidep, &
                                                           pcond, &
                                                           prevp, &
                                                           psevp, &
                                                           pgevp, &
                                                           psdep, &
                                                           pgdep, &
                                                           praut, &
                                                           psaut, &
                                                           pgaut, &
                                                           piacr, &
                                                           pracw, &
                                                           praci, &
                                                           pracs, &
                                                           psacw, &
                                                           psaci, &
                                                           psacr, &
                                                           pgacw, &
                                                           pgaci, &
                                                           pgacr, &
                                                           pgacs, &
                                                           paacw, &
                                                           psmlt, &
                                                           pgmlt, &
                                                           pseml, &
                                                           pgeml
  REAL, DIMENSION( 1:2 , 1:32 ) ::                         &
                                                            qsum, &
                                                              xl, &
                                                             cpm, &
                                                           work2, &
                                                          denfac, &
                                                             xni, &
                                                         denqrs1, &
                                                         denqrs2, &
                                                         denqrs3, &
                                                          denqci, & 
                                                          delta2, &
                                                          delta3, &
                                                           n0sfac
  REAL, DIMENSION( 1:2 ) ::                          delqrs1, &
                                                         delqrs2, &
                                                         delqrs3, &
                                                           delqi  
  REAL, DIMENSION( 1:2 ) ::                        tstepsnow, &
                                                      tstepgraup
  INTEGER, DIMENSION( 1:2 ) ::                         mstep, &
                                                           numdt
  LOGICAL, DIMENSION( 1:2 ) ::                        flgcld
  REAL  ::                                                        &
            cpmcal, xlcal, diffus,                                &
            viscos, xka, venfac, conden, diffac,                  &
            x, y, z, a, b, c, d, e,                               &
            qdt, holdrr, holdrs, holdrg, supcol, supcolt, pvt,    &
            coeres, supsat, dtcld, xmi, eacrs, satdt,             &
            qimax, diameter, xni0, roqi0,                         &
            fallsum, fallsum_qsi, fallsum_qg,                     &
            vt2i,vt2r,vt2s,vt2g,acrfac,egs,egi,                   &
            xlwork2, factor, source, value,                       &
            xlf, pfrzdtc, pfrzdtr, supice, alpha2
  REAL  :: vt2ave
  REAL  :: holdc, holdci
  INTEGER :: i, j, k, mstepmax,                                   &
            iprt, latd, lond, loop, loops, ifsat, n, idim, kdim
  INTEGER :: itest,ktest
! Temporaries used for inlining fpvs function
  REAL  :: dldti, xb, xai, tr, xbi, xa, hvap, cvap, hsub, dldt, ttp
! variables for optimization
  REAL, DIMENSION( 1:2 ) ::                             tvec1
  REAL                       ::                              temp
!
!=================================================================
!   compute internal functions
!
      cpmcal(x) = cpd*(1.-max(x,qmin))+max(x,qmin)*cpv
      xlcal(x) = xlv0-xlv1*(x-t0c)
!----------------------------------------------------------------
!     diffus: diffusion coefficient of the water vapor
!     viscos: kinematic viscosity(m2s-1)
!     Optimizatin : A**B => exp(log(A)*(B))
!
      diffus(x,y) = 8.794e-5 * exp(log(x)*(1.81)) / y        ! 8.794e-5*x**1.81/y
      viscos(x,y) = 1.496e-6 * (x*sqrt(x)) /(x+120.)/y  ! 1.496e-6*x**1.5/(x+120.)/y
      xka(x,y) = 1.414e3*viscos(x,y)*y
      diffac(a,b,c,d,e) = d*a*a/(xka(c,d)*rv*c*c)+1./(e*diffus(c,b))
      venfac(a,b,c) = exp(log((viscos(b,c)/diffus(b,a)))*((.3333333)))         &
                     /sqrt(viscos(b,c))*sqrt(sqrt(den0/c))
      conden(a,b,c,d,e) = (max(b,qmin)-c)/(1.+d*d/(rv*e)*c/(a*a))
!
!DIR$ ASSUME_ALIGNED t:64,qci:64,qrs:64,q:64,den:64,p:64,delz:64,rain:64,rainncv:64,sr:64
!DIR$ ASSUME_ALIGNED snow:64,snowncv:64,graupel:64,graupelncv:64,mstep:64,flgcld:64
!DIR$ ASSUME_ALIGNED worka:64,pgacs:64,n0sfac:64,work2:64,psmlt:64,rslope:64
!DIR$ ASSUME_ALIGNED rslope2:64,rslope3:64,rslopeb:64,cpm:64,pgmlt:64
!DIR$ ASSUME_ALIGNED tstepsnow:64,tstepgraup:64
!
      idim = ite-its+1
      kdim = kte-kts+1
itest=979
ktest=1
!
!----------------------------------------------------------------
!     padding 0 for negative values generated by dynamics
!
      do k =  1,32
        do i =  1,2
          qci(i,k,1) = max(qci(i,k,1),0.0)
          qrs(i,k,1) = max(qrs(i,k,1),0.0)
          qci(i,k,2) = max(qci(i,k,2),0.0)
          qrs(i,k,2) = max(qrs(i,k,2),0.0)
          qrs(i,k,3) = max(qrs(i,k,3),0.0)
        enddo
      enddo
!
!----------------------------------------------------------------
!     latent heat for phase changes and heat capacity. neglect the
!     changes during microphysical process calculation
!     emanuel(1994)
!
      do k =  1,32
        do i =  1,2
          cpm(i,k) = cpmcal(q(i,k))
          xl(i,k) = xlcal(t(i,k))
        enddo
      enddo
      do k =  1,32
        do i =  1,2
          delz_tmp(i,k) = delz(i,k)
          den_tmp(i,k) = den(i,k)
        enddo
      enddo
!
!----------------------------------------------------------------
!    initialize the surface rain, snow, graupel
!
      do i =  1,2
        rainncv(i) = 0.
        if(PRESENT (snowncv) .AND. PRESENT (snow)) snowncv(i,lat) = 0.
        if(PRESENT (graupelncv) .AND. PRESENT (graupel)) graupelncv(i,lat) = 0.
        sr(i) = 0.
! new local array to catch step snow and graupel
        tstepsnow(i) = 0.
        tstepgraup(i) = 0.
      enddo
!
!----------------------------------------------------------------
!     compute the minor time steps.
!
      loops = max(nint(delt/dtcldcr),1)
      dtcld = delt/loops
      if(delt.le.dtcldcr) dtcld = delt
!
      do loop = 1,loops
!
!----------------------------------------------------------------
!     initialize the large scale variables
!
!DIR$ VECTOR ALIGNED
      do i =  1,2
        mstep(i) = 1
        flgcld(i) = .true.
      enddo

      do k =  1,32
        do i =  1,2
          denfac(i,k) = sqrt(den0/den(i,k))
        enddo
      enddo
!
! Inline expansion for fpvs
!         qs(i,k,1) = fpvs(t(i,k),0,rd,rv,cpv,cliq,cice,xlv0,xls,psat,t0c)
!         qs(i,k,2) = fpvs(t(i,k),1,rd,rv,cpv,cliq,cice,xlv0,xls,psat,t0c)
      hsub = xls
      hvap = xlv0
      cvap = cpv
      ttp=t0c+0.01
      dldt=cvap-cliq
      xa=-dldt/rv
      xb=xa+hvap/(rv*ttp)
      dldti=cvap-cice
      xai=-dldti/rv
      xbi=xai+hsub/(rv*ttp)
      do k =  1,32
        do i =  1,2
          tr=ttp/t(i,k)
          qs(i,k,1)=psat*exp(log(tr)*(xa))*exp(xb*(1.-tr))
          qs(i,k,1) = min(qs(i,k,1),0.99*p(i,k))
          qs(i,k,1) = ep2 * qs(i,k,1) / (p(i,k) - qs(i,k,1))
          qs(i,k,1) = max(qs(i,k,1),qmin)
          rh(i,k,1) = max(q(i,k) / qs(i,k,1),qmin)
          tr=ttp/t(i,k)
          if(t(i,k).lt.ttp) then
            qs(i,k,2)=psat*exp(log(tr)*(xai))*exp(xbi*(1.-tr))
          else
            qs(i,k,2)=psat*exp(log(tr)*(xa))*exp(xb*(1.-tr))
          endif
          qs(i,k,2) = min(qs(i,k,2),0.99*p(i,k))
          qs(i,k,2) = ep2 * qs(i,k,2) / (p(i,k) - qs(i,k,2))
          qs(i,k,2) = max(qs(i,k,2),qmin)
          rh(i,k,2) = max(q(i,k) / qs(i,k,2),qmin)
        enddo
      enddo
!
!----------------------------------------------------------------
!     initialize the variables for microphysical physics
!
!
      do k =  1,32
        do i =  1,2
          prevp(i,k) = 0.
          psdep(i,k) = 0.
          pgdep(i,k) = 0.
          praut(i,k) = 0.
          psaut(i,k) = 0.
          pgaut(i,k) = 0.
          pracw(i,k) = 0.
          praci(i,k) = 0.
          piacr(i,k) = 0.
          psaci(i,k) = 0.
          psacw(i,k) = 0.
          pracs(i,k) = 0.
          psacr(i,k) = 0.
          pgacw(i,k) = 0.
          paacw(i,k) = 0.
          pgaci(i,k) = 0.
          pgacr(i,k) = 0.
          pgacs(i,k) = 0.
          pigen(i,k) = 0.
          pidep(i,k) = 0.
          pcond(i,k) = 0.
          psmlt(i,k) = 0.
          pgmlt(i,k) = 0.
          pseml(i,k) = 0.
          pgeml(i,k) = 0.
          psevp(i,k) = 0.
          pgevp(i,k) = 0.
          falk(i,k,1) = 0.
          falk(i,k,2) = 0.
          falk(i,k,3) = 0.
          fall(i,k,1) = 0.
          fall(i,k,2) = 0.
          fall(i,k,3) = 0.
          fallc(i,k) = 0.
          falkc(i,k) = 0.
          xni(i,k) = 1.e3
        enddo
      enddo
!-------------------------------------------------------------
! Ni: ice crystal number concentraiton   [HDC 5c]
!-------------------------------------------------------------
      do k =  1,32
        do i =  1,2
          temp = (den(i,k)*max(qci(i,k,2),qmin))
          temp = sqrt(sqrt(temp*temp*temp))
          xni(i,k) = min(max(5.38e7*temp,1.e3),1.e6)
        enddo
      enddo
!
!----------------------------------------------------------------
!     compute the fallout term:
!     first, vertical terminal velosity for minor loops
!----------------------------------------------------------------
      do k =  1,32
        do i =  1,2
          qrs_tmp(i,k,1) = qrs(i,k,1)
          qrs_tmp(i,k,2) = qrs(i,k,2)
          qrs_tmp(i,k,3) = qrs(i,k,3)
        enddo
      enddo
      call slope_wsm6(qrs_tmp,den_tmp,denfac,t,rslope,rslopeb,rslope2,rslope3, & 
                     work1,its,ite,kts,kte)
!
      do k =  32,1, -1
!DIR$ VECTOR ALIGNED
        do i =  1,2
          workr(i,k) = work1(i,k,1)
          qsum(i,k) = max( (qrs(i,k,2)+qrs(i,k,3)), 1.E-15)
          IF ( qsum(i,k) .gt. 1.e-15 ) THEN
            worka(i,k) = (work1(i,k,2)*qrs(i,k,2) + work1(i,k,3)*qrs(i,k,3)) &
                      /qsum(i,k)
          ELSE
            worka(i,k) = 0.
          ENDIF
          denqrs1(i,k) = den(i,k)*qrs(i,k,1)
          denqrs2(i,k) = den(i,k)*qrs(i,k,2)
          denqrs3(i,k) = den(i,k)*qrs(i,k,3)
          if(qrs(i,k,1).le.0.0) workr(i,k) = 0.0
        enddo
      enddo
      call nislfv_rain_plm(its,ite,kts,kte,den_tmp,denfac,t,delz_tmp,workr,denqrs1,  &
                           delqrs1,dtcld,1,1)
      call nislfv_rain_plm6(its,ite,kts,kte,den_tmp,denfac,t,delz_tmp,worka,         & 
                           denqrs2,denqrs3,delqrs2,delqrs3,dtcld,1,1)
      do k =  1,32
        do i =  1,2
          qrs(i,k,1) = max(denqrs1(i,k)/den(i,k),0.)
          qrs(i,k,2) = max(denqrs2(i,k)/den(i,k),0.)
          qrs(i,k,3) = max(denqrs3(i,k)/den(i,k),0.)
          fall(i,k,1) = denqrs1(i,k)*workr(i,k)/delz(i,k)
          fall(i,k,2) = denqrs2(i,k)*worka(i,k)/delz(i,k)
          fall(i,k,3) = denqrs3(i,k)*worka(i,k)/delz(i,k)
        enddo
      enddo
      do i =  1,2
        fall(i,1,1) = delqrs1(i)/delz(i,1)/dtcld
        fall(i,1,2) = delqrs2(i)/delz(i,1)/dtcld
        fall(i,1,3) = delqrs3(i)/delz(i,1)/dtcld
      enddo
      do k =  1,32
        do i =  1,2
          qrs_tmp(i,k,1) = qrs(i,k,1)
          qrs_tmp(i,k,2) = qrs(i,k,2)
          qrs_tmp(i,k,3) = qrs(i,k,3)
        enddo
      enddo
      call slope_wsm6(qrs_tmp,den_tmp,denfac,t,rslope,rslopeb,rslope2,rslope3, &
                     work1,its,ite,kts,kte)
!
      do k =  32,1, -1 
!DIR$ VECTOR ALIGNED
        do i =  1,2
          supcol = t0c-t(i,k)
          n0sfac(i,k) = max(min(exp(alpha*supcol),n0smax/n0s),1.)
          if(t(i,k).gt.t0c) then
!---------------------------------------------------------------
! psmlt: melting of snow [HL A33] [RH83 A25]
!       (T>T0: S->R)
!---------------------------------------------------------------
            xlf = xlf0
            work2(i,k) = venfac(p(i,k),t(i,k),den(i,k))
            if(qrs(i,k,2).gt.0.) then
              coeres = rslope2(i,k,2)*sqrt(rslope(i,k,2)*rslopeb(i,k,2))
              psmlt(i,k) = xka(t(i,k),den(i,k))/xlf*(t0c-t(i,k))*pi/2.       &
                         *n0sfac(i,k)*(precs1*rslope2(i,k,2)                 &
                         +precs2*work2(i,k)*coeres)
              psmlt(i,k) = min(max(psmlt(i,k)*dtcld/mstep(i),                &
                          -qrs(i,k,2)/mstep(i)),0.)
              qrs(i,k,2) = qrs(i,k,2) + psmlt(i,k)
              qrs(i,k,1) = qrs(i,k,1) - psmlt(i,k)
              t(i,k) = t(i,k) + xlf/cpm(i,k)*psmlt(i,k)
            endif
!---------------------------------------------------------------
! pgmlt: melting of graupel [HL A23]  [LFO 47]
!       (T>T0: G->R)
!---------------------------------------------------------------
            if(qrs(i,k,3).gt.0.) then
              coeres = rslope2(i,k,3)*sqrt(rslope(i,k,3)*rslopeb(i,k,3))
              pgmlt(i,k) = xka(t(i,k),den(i,k))/xlf                          &
                         *(t0c-t(i,k))*(precg1*rslope2(i,k,3)                &
                         +precg2*work2(i,k)*coeres)
              pgmlt(i,k) = min(max(pgmlt(i,k)*dtcld/mstep(i),                &
                          -qrs(i,k,3)/mstep(i)),0.)                          
              qrs(i,k,3) = qrs(i,k,3) + pgmlt(i,k)
              qrs(i,k,1) = qrs(i,k,1) - pgmlt(i,k)
              t(i,k) = t(i,k) + xlf/cpm(i,k)*pgmlt(i,k)
            endif
          endif
        enddo
      enddo
!---------------------------------------------------------------
! Vice [ms-1] : fallout of ice crystal [HDC 5a]
!---------------------------------------------------------------
      do k =  32,1, -1
        do i =  1,2
          if(qci(i,k,2).le.0.) then
            work1c(i,k) = 0.
          else
            xmi = den(i,k)*qci(i,k,2)/xni(i,k)
            diameter  = max(min(dicon * sqrt(xmi),dimax), 1.e-25)
            work1c(i,k) = 1.49e4*exp(log(diameter)*(1.31))
          endif
        enddo
      enddo
!
!  forward semi-laglangian scheme (JH), PCM (piecewise constant),  (linear)
!
      do k =  32,1, -1
        do i =  1,2
          denqci(i,k) = den(i,k)*qci(i,k,2)
        enddo
      enddo
      call nislfv_rain_plm(its,ite,kts,kte,den_tmp,denfac,t,delz_tmp,work1c,denqci,  &
                           delqi,dtcld,1,0)
      do k =  1,32
        do i =  1,2
          qci(i,k,2) = max(denqci(i,k)/den(i,k),0.)
        enddo
      enddo
      do i =  1,2
        fallc(i,1) = delqi(i)/delz(i,1)/dtcld
      enddo
!
!----------------------------------------------------------------
!      rain (unit is mm/sec;kgm-2s-1: /1000*delt ===> m)==> mm for wrf
!
!DIR$ VECTOR ALIGNED
      do i =  1,2
        fallsum = fall(i,kts,1)+fall(i,kts,2)+fall(i,kts,3)+fallc(i,kts)
        fallsum_qsi = fall(i,kts,2)+fallc(i,kts)
        fallsum_qg = fall(i,kts,3)
        if(fallsum.gt.0.) then
          rainncv(i) = fallsum*delz(i,kts)/denr*dtcld*1000. + rainncv(i)
          rain(i) = fallsum*delz(i,kts)/denr*dtcld*1000. + rain(i)
        endif
        if(fallsum_qsi.gt.0.) then
          tstepsnow(i)   = fallsum_qsi*delz(i,kts)/denr*dtcld*1000.            &
                           +tstepsnow(i)
        IF ( PRESENT (snowncv) .AND. PRESENT (snow)) THEN
          snowncv(i,lat) = fallsum_qsi*delz(i,kts)/denr*dtcld*1000.            & 
                           +snowncv(i,lat)
          snow(i,lat) = fallsum_qsi*delz(i,kts)/denr*dtcld*1000. + snow(i,lat)
        ENDIF
        endif
        if(fallsum_qg.gt.0.) then
          tstepgraup(i)  = fallsum_qsi*delz(i,kts)/denr*dtcld*1000.            &
                           +tstepgraup(i)
        IF ( PRESENT (graupelncv) .AND. PRESENT (graupel)) THEN
          graupelncv(i,lat) = fallsum_qg*delz(i,kts)/denr*dtcld*1000.          &   
                              + graupelncv(i,lat)
          graupel(i,lat) = fallsum_qg*delz(i,kts)/denr*dtcld*1000. + graupel(i,lat)
        ENDIF
        endif
!       if(fallsum.gt.0.)sr(i)=(snowncv(i,lat) + graupelncv(i,lat))/(rainncv(i)+1.e-12)
        if(fallsum.gt.0.)sr(i)=(tstepsnow(i) + tstepgraup(i))/(rainncv(i)+1.e-12)
      enddo
!
!---------------------------------------------------------------
! pimlt: instantaneous melting of cloud ice [HL A47] [RH83 A28]
!       (T>T0: I->C)
!---------------------------------------------------------------
      do k =  1,32
        do i =  1,2
          supcol = t0c-t(i,k)
          xlf = xls-xl(i,k)
          if(supcol.lt.0.) xlf = xlf0
          if(supcol.lt.0.and.qci(i,k,2).gt.0.) then
            qci(i,k,1) = qci(i,k,1) + qci(i,k,2)
            t(i,k) = t(i,k) - xlf/cpm(i,k)*qci(i,k,2)
            qci(i,k,2) = 0.
          endif
!---------------------------------------------------------------
! pihmf: homogeneous freezing of cloud water below -40c [HL A45]
!        (T<-40C: C->I)
!---------------------------------------------------------------
          if(supcol.gt.40..and.qci(i,k,1).gt.0.) then
            qci(i,k,2) = qci(i,k,2) + qci(i,k,1)
            t(i,k) = t(i,k) + xlf/cpm(i,k)*qci(i,k,1)
            qci(i,k,1) = 0.
          endif
!---------------------------------------------------------------
! pihtf: heterogeneous freezing of cloud water [HL A44]
!        (T0>T>-40C: C->I)
!---------------------------------------------------------------
          if(supcol.gt.0..and.qci(i,k,1).gt.qmin) then
!           pfrzdtc = min(pfrz1*(exp(pfrz2*supcol)-1.)                         &
!              *den(i,k)/denr/xncr*qci(i,k,1)**2*dtcld,qci(i,k,1))
            supcolt=min(supcol,50.)
            pfrzdtc = min(pfrz1*(exp(pfrz2*supcolt)-1.)                        &
            *den(i,k)/denr/xncr*qci(i,k,1)*qci(i,k,1)*dtcld,qci(i,k,1))
            qci(i,k,2) = qci(i,k,2) + pfrzdtc
            t(i,k) = t(i,k) + xlf/cpm(i,k)*pfrzdtc
            qci(i,k,1) = qci(i,k,1)-pfrzdtc
          endif
!---------------------------------------------------------------
! pgfrz: freezing of rain water [HL A20] [LFO 45]
!        (T<T0, R->G)
!---------------------------------------------------------------
          if(supcol.gt.0..and.qrs(i,k,1).gt.0.) then
!           pfrzdtr = min(20.*pi**2*pfrz1*n0r*denr/den(i,k)                    &
!                 *(exp(pfrz2*supcol)-1.)*rslope3(i,k,1)**2                    &
!                 *rslope(i,k,1)*dtcld,qrs(i,k,1))
            temp = rslope3(i,k,1)
            temp = temp*temp*rslope(i,k,1)
            supcolt=min(supcol,50.)
            pfrzdtr = min(20.*(pi*pi)*pfrz1*n0r*denr/den(i,k)                  &
                  *(exp(pfrz2*supcolt)-1.)*temp*dtcld,                         &
                  qrs(i,k,1))
            qrs(i,k,3) = qrs(i,k,3) + pfrzdtr
            t(i,k) = t(i,k) + xlf/cpm(i,k)*pfrzdtr
            qrs(i,k,1) = qrs(i,k,1)-pfrzdtr
          endif
        enddo
      enddo
!
!
!----------------------------------------------------------------
!     update the slope parameters for microphysics computation
!
      do k =  1,32
        do i =  1,2
          qrs_tmp(i,k,1) = qrs(i,k,1)
          qrs_tmp(i,k,2) = qrs(i,k,2)
          qrs_tmp(i,k,3) = qrs(i,k,3)
        enddo
      enddo
      call slope_wsm6(qrs_tmp,den_tmp,denfac,t,rslope,rslopeb,rslope2,rslope3, &
                     work1,its,ite,kts,kte)
!------------------------------------------------------------------
!     work1:  the thermodynamic term in the denominator associated with
!             heat conduction and vapor diffusion
!             (ry88, y93, h85)
!     work2: parameter associated with the ventilation effects(y93)
!
      do k =  1,32
        do i =  1,2
          work1(i,k,1) = diffac(xl(i,k),p(i,k),t(i,k),den(i,k),qs(i,k,1))
          work1(i,k,2) = diffac(xls,p(i,k),t(i,k),den(i,k),qs(i,k,2))
          work2(i,k) = venfac(p(i,k),t(i,k),den(i,k))
        enddo
      enddo
!
!===============================================================
!
! warm rain processes
!
! - follows the processes in RH83 and LFO except for autoconcersion
!
!===============================================================
!
      do k =  1,32
!DIR$ VECTOR ALIGNED
        do i =  1,2
          supsat = max(q(i,k),qmin)-qs(i,k,1)
          satdt = supsat/dtcld
!---------------------------------------------------------------
! praut: auto conversion rate from cloud to rain [HDC 16]
!        (C->R)
!---------------------------------------------------------------
          if(qci(i,k,1).gt.qc0) then
            praut(i,k) = qck1*qci(i,k,1)**(7./3.)
            praut(i,k) = min(praut(i,k),qci(i,k,1)/dtcld)
          endif
!---------------------------------------------------------------
! pracw: accretion of cloud water by rain [HL A40] [LFO 51]
!        (C->R)
!---------------------------------------------------------------
          if(qrs(i,k,1).gt.qcrmin.and.qci(i,k,1).gt.qmin) then
            pracw(i,k) = min(pacrr*rslope3(i,k,1)*rslopeb(i,k,1)               &
                        *qci(i,k,1)*denfac(i,k),qci(i,k,1)/dtcld)
          endif
!---------------------------------------------------------------
! prevp: evaporation/condensation rate of rain [HDC 14]
!        (V->R or R->V)
!---------------------------------------------------------------
          if(qrs(i,k,1).gt.0.) then
            coeres = rslope2(i,k,1)*sqrt(rslope(i,k,1)*rslopeb(i,k,1))
            prevp(i,k) = (rh(i,k,1)-1.)*(precr1*rslope2(i,k,1)                 &
                         +precr2*work2(i,k)*coeres)/work1(i,k,1)
            if(prevp(i,k).lt.0.) then
              prevp(i,k) = max(prevp(i,k),-qrs(i,k,1)/dtcld)
              prevp(i,k) = max(prevp(i,k),satdt/2)
            else
              prevp(i,k) = min(prevp(i,k),satdt/2)
            endif
          endif
        enddo
      enddo
!
!===============================================================
!
! cold rain processes
!
! - follows the revised ice microphysics processes in HDC
! - the processes same as in RH83 and RH84  and LFO behave
!   following ice crystal hapits defined in HDC, inclduing
!   intercept parameter for snow (n0s), ice crystal number
!   concentration (ni), ice nuclei number concentration
!   (n0i), ice diameter (d)
!
!===============================================================
!
      do k =  1,32
!DIR$ VECTOR ALIGNED
        do i =  1,2
          supcol = t0c-t(i,k)
          n0sfac(i,k) = max(min(exp(alpha*supcol),n0smax/n0s),1.)
          supsat = max(q(i,k),qmin)-qs(i,k,2)
          satdt = supsat/dtcld
          ifsat = 0
!-------------------------------------------------------------
! Ni: ice crystal number concentraiton   [HDC 5c]
!-------------------------------------------------------------
!         xni(i,k) = min(max(5.38e7*(den(i,k)                                  &
!                      *max(qci(i,k,2),qmin))**0.75,1.e3),1.e6)
          temp = (den(i,k)*max(qci(i,k,2),qmin))
          temp = sqrt(sqrt(temp*temp*temp))
          xni(i,k) = min(max(5.38e7*temp,1.e3),1.e6)
          eacrs = exp(0.07*(-supcol))
!
          xmi = den(i,k)*qci(i,k,2)/xni(i,k)
          diameter  = min(dicon * sqrt(xmi),dimax)
          vt2i = 1.49e4*diameter**1.31
          vt2r=pvtr*rslopeb(i,k,1)*denfac(i,k)
          vt2s=pvts*rslopeb(i,k,2)*denfac(i,k)
          vt2g=pvtg*rslopeb(i,k,3)*denfac(i,k)
          qsum(i,k) = max( (qrs(i,k,2)+qrs(i,k,3)), 1.E-15)
          if(qsum(i,k) .gt. 1.e-15) then
          vt2ave=(vt2s*qrs(i,k,2)+vt2g*qrs(i,k,3))/(qsum(i,k))
          else
          vt2ave=0.
          endif
          if(supcol.gt.0.and.qci(i,k,2).gt.qmin) then
            if(qrs(i,k,1).gt.qcrmin) then
!-------------------------------------------------------------
! praci: Accretion of cloud ice by rain [HL A15] [LFO 25]
!        (T<T0: I->R)
!-------------------------------------------------------------
              acrfac = 2.*rslope3(i,k,1)+2.*diameter*rslope2(i,k,1)            &
                      +diameter**2*rslope(i,k,1)
              praci(i,k) = pi*qci(i,k,2)*n0r*abs(vt2r-vt2i)*acrfac/4.
              praci(i,k) = min(praci(i,k),qci(i,k,2)/dtcld)
!-------------------------------------------------------------
! piacr: Accretion of rain by cloud ice [HL A19] [LFO 26]
!        (T<T0: R->S or R->G)
!-------------------------------------------------------------
              piacr(i,k) = pi**2*avtr*n0r*denr*xni(i,k)*denfac(i,k)            &
                          *g6pbr*rslope3(i,k,1)*rslope3(i,k,1)                 &
                          *rslopeb(i,k,1)/24./den(i,k)
              piacr(i,k) = min(piacr(i,k),qrs(i,k,1)/dtcld)
            endif
!-------------------------------------------------------------
! psaci: Accretion of cloud ice by snow [HDC 10]
!        (T<T0: I->S)
!-------------------------------------------------------------
            if(qrs(i,k,2).gt.qcrmin) then
              acrfac = 2.*rslope3(i,k,2)+2.*diameter*rslope2(i,k,2)            &
                      +diameter**2*rslope(i,k,2)
              psaci(i,k) = pi*qci(i,k,2)*eacrs*n0s*n0sfac(i,k)                 &
                          *abs(vt2ave-vt2i)*acrfac/4.
              psaci(i,k) = min(psaci(i,k),qci(i,k,2)/dtcld)
            endif
!-------------------------------------------------------------
! pgaci: Accretion of cloud ice by graupel [HL A17] [LFO 41]
!        (T<T0: I->G)
!-------------------------------------------------------------
            if(qrs(i,k,3).gt.qcrmin) then
              egi = exp(0.07*(-supcol))
              acrfac = 2.*rslope3(i,k,3)+2.*diameter*rslope2(i,k,3)            &
                      +diameter**2*rslope(i,k,3)
              pgaci(i,k) = pi*egi*qci(i,k,2)*n0g*abs(vt2ave-vt2i)*acrfac/4.
              pgaci(i,k) = min(pgaci(i,k),qci(i,k,2)/dtcld)
            endif
          endif
!-------------------------------------------------------------
! psacw: Accretion of cloud water by snow  [HL A7] [LFO 24]
!        (T<T0: C->S, and T>=T0: C->R)
!-------------------------------------------------------------
          if(qrs(i,k,2).gt.qcrmin.and.qci(i,k,1).gt.qmin) then
            psacw(i,k) = min(pacrc*n0sfac(i,k)*rslope3(i,k,2)*rslopeb(i,k,2)   &    
                        *qci(i,k,1)*denfac(i,k),qci(i,k,1)/dtcld)
          endif
!-------------------------------------------------------------
! pgacw: Accretion of cloud water by graupel [HL A6] [LFO 40]
!        (T<T0: C->G, and T>=T0: C->R)
!-------------------------------------------------------------
          if(qrs(i,k,3).gt.qcrmin.and.qci(i,k,1).gt.qmin) then
            pgacw(i,k) = min(pacrg*rslope3(i,k,3)*rslopeb(i,k,3)               &
                        *qci(i,k,1)*denfac(i,k),qci(i,k,1)/dtcld)
          endif
!-------------------------------------------------------------
! paacw: Accretion of cloud water by averaged snow/graupel 
!        (T<T0: C->G or S, and T>=T0: C->R) 
!-------------------------------------------------------------
          if(qrs(i,k,2).gt.qcrmin.and.qrs(i,k,3).gt.qcrmin) then
            paacw(i,k) = (qrs(i,k,2)*psacw(i,k)+qrs(i,k,3)*pgacw(i,k))         & 
                        /(qsum(i,k))
           endif      
!-------------------------------------------------------------
! pracs: Accretion of snow by rain [HL A11] [LFO 27]
!         (T<T0: S->G)
!-------------------------------------------------------------
          if(qrs(i,k,2).gt.qcrmin.and.qrs(i,k,1).gt.qcrmin) then
            if(supcol.gt.0) then
              acrfac = 5.*rslope3(i,k,2)*rslope3(i,k,2)*rslope(i,k,1)          &
                      +2.*rslope3(i,k,2)*rslope2(i,k,2)*rslope2(i,k,1)         &
                      +.5*rslope2(i,k,2)*rslope2(i,k,2)*rslope3(i,k,1)
              pracs(i,k) = pi**2*n0r*n0s*n0sfac(i,k)*abs(vt2r-vt2ave)          &
                          *(dens/den(i,k))*acrfac
              pracs(i,k) = min(pracs(i,k),qrs(i,k,2)/dtcld)
            endif
!-------------------------------------------------------------
! psacr: Accretion of rain by snow [HL A10] [LFO 28]
!         (T<T0:R->S or R->G) (T>=T0: enhance melting of snow)
!-------------------------------------------------------------
            acrfac = 5.*rslope3(i,k,1)*rslope3(i,k,1)*rslope(i,k,2)            &
                    +2.*rslope3(i,k,1)*rslope2(i,k,1)*rslope2(i,k,2)           &
                    +.5*rslope2(i,k,1)*rslope2(i,k,1)*rslope3(i,k,2)
            psacr(i,k) = pi**2*n0r*n0s*n0sfac(i,k)*abs(vt2ave-vt2r)            &
                        *(denr/den(i,k))*acrfac
            psacr(i,k) = min(psacr(i,k),qrs(i,k,1)/dtcld)
          endif
!-------------------------------------------------------------
! pgacr: Accretion of rain by graupel [HL A12] [LFO 42]
!         (T<T0: R->G) (T>=T0: enhance melting of graupel)
!-------------------------------------------------------------
          if(qrs(i,k,3).gt.qcrmin.and.qrs(i,k,1).gt.qcrmin) then
            acrfac = 5.*rslope3(i,k,1)*rslope3(i,k,1)*rslope(i,k,3)            &
                    +2.*rslope3(i,k,1)*rslope2(i,k,1)*rslope2(i,k,3)           &
                    +.5*rslope2(i,k,1)*rslope2(i,k,1)*rslope3(i,k,3)
            pgacr(i,k) = pi**2*n0r*n0g*abs(vt2ave-vt2r)*(denr/den(i,k))        &
                        *acrfac
            pgacr(i,k) = min(pgacr(i,k),qrs(i,k,1)/dtcld)
          endif
!
!-------------------------------------------------------------
! pgacs: Accretion of snow by graupel [HL A13] [LFO 29]
!        (S->G): This process is eliminated in V3.0 with the 
!        new combined snow/graupel fall speeds
!-------------------------------------------------------------
          if(qrs(i,k,3).gt.qcrmin.and.qrs(i,k,2).gt.qcrmin) then
            pgacs(i,k) = 0.
          endif
          if(supcol.le.0) then
            xlf = xlf0
!-------------------------------------------------------------
! pseml: Enhanced melting of snow by accretion of water [HL A34]
!        (T>=T0: S->R)
!-------------------------------------------------------------
            if(qrs(i,k,2).gt.0.)                                               &
              pseml(i,k) = min(max(cliq*supcol*(paacw(i,k)+psacr(i,k))         &
                          /xlf,-qrs(i,k,2)/dtcld),0.)
!-------------------------------------------------------------
! pgeml: Enhanced melting of graupel by accretion of water [HL A24] [RH84 A21-A22]
!        (T>=T0: G->R)
!-------------------------------------------------------------
            if(qrs(i,k,3).gt.0.)                                               &
              pgeml(i,k) = min(max(cliq*supcol*(paacw(i,k)+pgacr(i,k))         &
                          /xlf,-qrs(i,k,3)/dtcld),0.)
          endif
          if(supcol.gt.0) then
!-------------------------------------------------------------
! pidep: Deposition/Sublimation rate of ice [HDC 9]
!       (T<T0: V->I or I->V)
!-------------------------------------------------------------
            if(qci(i,k,2).gt.0.and.ifsat.ne.1) then
              pidep(i,k) = 4.*diameter*xni(i,k)*(rh(i,k,2)-1.)/work1(i,k,2)
              supice = satdt-prevp(i,k)
              if(pidep(i,k).lt.0.) then
                pidep(i,k) = max(max(pidep(i,k),satdt/2),supice)
                pidep(i,k) = max(pidep(i,k),-qci(i,k,2)/dtcld)
              else
                pidep(i,k) = min(min(pidep(i,k),satdt/2),supice)
              endif
              if(abs(prevp(i,k)+pidep(i,k)).ge.abs(satdt)) ifsat = 1
            endif
!-------------------------------------------------------------
! psdep: deposition/sublimation rate of snow [HDC 14]
!        (T<T0: V->S or S->V)
!-------------------------------------------------------------
            if(qrs(i,k,2).gt.0..and.ifsat.ne.1) then
              coeres = rslope2(i,k,2)*sqrt(rslope(i,k,2)*rslopeb(i,k,2))
              psdep(i,k) = (rh(i,k,2)-1.)*n0sfac(i,k)*(precs1*rslope2(i,k,2)   &    
                           + precs2*work2(i,k)*coeres)/work1(i,k,2)
              supice = satdt-prevp(i,k)-pidep(i,k)
              if(psdep(i,k).lt.0.) then
                psdep(i,k) = max(psdep(i,k),-qrs(i,k,2)/dtcld)
                psdep(i,k) = max(max(psdep(i,k),satdt/2),supice)
              else
                psdep(i,k) = min(min(psdep(i,k),satdt/2),supice)
              endif
              if(abs(prevp(i,k)+pidep(i,k)+psdep(i,k)).ge.abs(satdt))          &
                ifsat = 1
            endif
!-------------------------------------------------------------
! pgdep: deposition/sublimation rate of graupel [HL A21] [LFO 46]
!        (T<T0: V->G or G->V)
!-------------------------------------------------------------
            if(qrs(i,k,3).gt.0..and.ifsat.ne.1) then
              coeres = rslope2(i,k,3)*sqrt(rslope(i,k,3)*rslopeb(i,k,3))
              pgdep(i,k) = (rh(i,k,2)-1.)*(precg1*rslope2(i,k,3)               &
                              +precg2*work2(i,k)*coeres)/work1(i,k,2)
              supice = satdt-prevp(i,k)-pidep(i,k)-psdep(i,k)
              if(pgdep(i,k).lt.0.) then
                pgdep(i,k) = max(pgdep(i,k),-qrs(i,k,3)/dtcld)
                pgdep(i,k) = max(max(pgdep(i,k),satdt/2),supice)
              else
                pgdep(i,k) = min(min(pgdep(i,k),satdt/2),supice)
              endif
              if(abs(prevp(i,k)+pidep(i,k)+psdep(i,k)+pgdep(i,k)).ge.          &
                abs(satdt)) ifsat = 1
            endif
!-------------------------------------------------------------
! pigen: generation(nucleation) of ice from vapor [HL 50] [HDC 7-8]
!       (T<T0: V->I)
!-------------------------------------------------------------
            if(supsat.gt.0.and.ifsat.ne.1) then
              supice = satdt-prevp(i,k)-pidep(i,k)-psdep(i,k)-pgdep(i,k)
              xni0 = 1.e3*exp(0.1*supcol)
              roqi0 = 4.92e-11*xni0**1.33
              pigen(i,k) = max(0.,(roqi0/den(i,k)-max(qci(i,k,2),0.))/dtcld)
              pigen(i,k) = min(min(pigen(i,k),satdt),supice)
            endif
!
!-------------------------------------------------------------
! psaut: conversion(aggregation) of ice to snow [HDC 12]
!        (T<T0: I->S)
!-------------------------------------------------------------
            if(qci(i,k,2).gt.0.) then
              qimax = roqimax/den(i,k)
              psaut(i,k) = max(0.,(qci(i,k,2)-qimax)/dtcld)
            endif
!
!-------------------------------------------------------------
! pgaut: conversion(aggregation) of snow to graupel [HL A4] [LFO 37]
!        (T<T0: S->G)
!-------------------------------------------------------------
            if(qrs(i,k,2).gt.0.) then
              alpha2 = 1.e-3*exp(0.09*(-supcol))
              pgaut(i,k) = min(max(0.,alpha2*(qrs(i,k,2)-qs0)),qrs(i,k,2)/dtcld)
            endif
          endif
!
!-------------------------------------------------------------
! psevp: Evaporation of melting snow [HL A35] [RH83 A27]
!       (T>=T0: S->V)
!-------------------------------------------------------------
          if(supcol.lt.0.) then
            if(qrs(i,k,2).gt.0..and.rh(i,k,1).lt.1.) then
              coeres = rslope2(i,k,2)*sqrt(rslope(i,k,2)*rslopeb(i,k,2))
              psevp(i,k) = (rh(i,k,1)-1.)*n0sfac(i,k)*(precs1                  &
                           *rslope2(i,k,2)+precs2*work2(i,k)                   &
                           *coeres)/work1(i,k,1)
              psevp(i,k) = min(max(psevp(i,k),-qrs(i,k,2)/dtcld),0.)
            endif
!-------------------------------------------------------------
! pgevp: Evaporation of melting graupel [HL A25] [RH84 A19]
!       (T>=T0: G->V)
!-------------------------------------------------------------
            if(qrs(i,k,3).gt.0..and.rh(i,k,1).lt.1.) then
              coeres = rslope2(i,k,3)*sqrt(rslope(i,k,3)*rslopeb(i,k,3))
              pgevp(i,k) = (rh(i,k,1)-1.)*(precg1*rslope2(i,k,3)               &
                         +precg2*work2(i,k)*coeres)/work1(i,k,1)
              pgevp(i,k) = min(max(pgevp(i,k),-qrs(i,k,3)/dtcld),0.)
            endif
          endif
        enddo
      enddo
!
!
!----------------------------------------------------------------
!     check mass conservation of generation terms and feedback to the
!     large scale
!
      do k =  1,32
!DIR$ VECTOR ALIGNED
        do i =  1,2
          delta2(i,k)=0.
          delta3(i,k)=0.
          if(qrs(i,k,1).lt.1.e-4.and.qrs(i,k,2).lt.1.e-4) delta2(i,k)=1.
          if(qrs(i,k,1).lt.1.e-4) delta3(i,k)=1.
        enddo
      enddo
      do k =  1,32
!DIR$ VECTOR ALIGNED
        do i =  1,2
!
!     cloud water
!
          value = max(qmin,qci(i,k,1))
          source = (praut(i,k)+pracw(i,k)+paacw(i,k)+paacw(i,k))*dtcld
          if(t(i,k).le.t0c) then
            if (source.gt.value) then
              factor = value/source
              praut(i,k) = praut(i,k)*factor
              pracw(i,k) = pracw(i,k)*factor
              paacw(i,k) = paacw(i,k)*factor
            endif
          else
            if (source.gt.value) then
              factor = value/source
              praut(i,k) = praut(i,k)*factor
              pracw(i,k) = pracw(i,k)*factor
              paacw(i,k) = paacw(i,k)*factor
            endif
          endif
        enddo
      enddo
      do k =  1,32
!DIR$ VECTOR ALIGNED
        do i =  1,2
!
!     cloud ice
!
          if(t(i,k).le.t0c) then
            value = max(qmin,qci(i,k,2))
            source = (psaut(i,k)-pigen(i,k)-pidep(i,k)+praci(i,k)+psaci(i,k)   &
                     +pgaci(i,k))*dtcld
            if (source.gt.value) then
              factor = value/source
              psaut(i,k) = psaut(i,k)*factor
              pigen(i,k) = pigen(i,k)*factor
              pidep(i,k) = pidep(i,k)*factor
              praci(i,k) = praci(i,k)*factor
              psaci(i,k) = psaci(i,k)*factor
              pgaci(i,k) = pgaci(i,k)*factor
            endif
          endif
        enddo
      enddo
      do k =  1,32
!DIR$ VECTOR ALIGNED
        do i =  1,2
!
!     rain
!
          value = max(qmin,qrs(i,k,1))
          if(t(i,k).le.t0c) then
            source = (-praut(i,k)-prevp(i,k)-pracw(i,k)+piacr(i,k)+psacr(i,k)  &
                      +pgacr(i,k))*dtcld
            if (source.gt.value) then
              factor = value/source
              praut(i,k) = praut(i,k)*factor
              prevp(i,k) = prevp(i,k)*factor
              pracw(i,k) = pracw(i,k)*factor
              piacr(i,k) = piacr(i,k)*factor
              psacr(i,k) = psacr(i,k)*factor
              pgacr(i,k) = pgacr(i,k)*factor
            endif
          else
            source = (-paacw(i,k)-praut(i,k)+pseml(i,k)+pgeml(i,k)-pracw(i,k)  &
                      -paacw(i,k)-prevp(i,k))*dtcld
            if (source.gt.value) then
              factor = value/source
              praut(i,k) = praut(i,k)*factor
              prevp(i,k) = prevp(i,k)*factor
              pracw(i,k) = pracw(i,k)*factor
              paacw(i,k) = paacw(i,k)*factor
              pseml(i,k) = pseml(i,k)*factor
              pgeml(i,k) = pgeml(i,k)*factor
            endif
          endif
        enddo
      enddo
      do k =  1,32
!DIR$ VECTOR ALIGNED
        do i =  1,2
!
!     snow
!
          if(t(i,k).le.t0c) then
            value = max(qmin,qrs(i,k,2))
            source = -(psdep(i,k)+psaut(i,k)-pgaut(i,k)+paacw(i,k)+piacr(i,k)  &
                     *delta3(i,k)+praci(i,k)*delta3(i,k)                       &
                     -pracs(i,k)*(1.-delta2(i,k))                              &
                     +psacr(i,k)*delta2(i,k)+psaci(i,k)-pgacs(i,k) )*dtcld
            if (source.gt.value) then
              factor = value/source
              psdep(i,k) = psdep(i,k)*factor
              psaut(i,k) = psaut(i,k)*factor
              pgaut(i,k) = pgaut(i,k)*factor
              paacw(i,k) = paacw(i,k)*factor
              piacr(i,k) = piacr(i,k)*factor
              praci(i,k) = praci(i,k)*factor
              psaci(i,k) = psaci(i,k)*factor
              pracs(i,k) = pracs(i,k)*factor
              psacr(i,k) = psacr(i,k)*factor
              pgacs(i,k) = pgacs(i,k)*factor
            endif
          else
            value = max(qcrmin,qrs(i,k,2))
            source=(pgacs(i,k)-pseml(i,k)-psevp(i,k))*dtcld
            if (source.gt.value) then
              factor = value/source
              pgacs(i,k) = pgacs(i,k)*factor
              psevp(i,k) = psevp(i,k)*factor
              pseml(i,k) = pseml(i,k)*factor
            endif
          endif
        enddo
      enddo
      do k =  1,32
!DIR$ VECTOR ALIGNED
        do i =  1,2
!
!     graupel
!
          if(t(i,k).le.t0c) then
            value = max(qmin,qrs(i,k,3))
            source = -(pgdep(i,k)+pgaut(i,k)                                   &
                     +piacr(i,k)*(1.-delta3(i,k))+praci(i,k)*(1.-delta3(i,k))  &
                     +psacr(i,k)*(1.-delta2(i,k))+pracs(i,k)*(1.-delta2(i,k))  &
                     +pgaci(i,k)+paacw(i,k)+pgacr(i,k)+pgacs(i,k))*dtcld
            if (source.gt.value) then
              factor = value/source
              pgdep(i,k) = pgdep(i,k)*factor
              pgaut(i,k) = pgaut(i,k)*factor
              piacr(i,k) = piacr(i,k)*factor
              praci(i,k) = praci(i,k)*factor
              psacr(i,k) = psacr(i,k)*factor
              pracs(i,k) = pracs(i,k)*factor
              paacw(i,k) = paacw(i,k)*factor
              pgaci(i,k) = pgaci(i,k)*factor
              pgacr(i,k) = pgacr(i,k)*factor
              pgacs(i,k) = pgacs(i,k)*factor
            endif
          else
            value = max(qcrmin,qrs(i,k,3))
            source=-(pgacs(i,k)+pgevp(i,k)+pgeml(i,k))*dtcld
            if (source.gt.value) then
              factor = value/source
              pgacs(i,k) = pgacs(i,k)*factor
              pgevp(i,k) = pgevp(i,k)*factor
              pgeml(i,k) = pgeml(i,k)*factor
            endif
          endif
        enddo
      enddo
      do k =  1,32
!DIR$ VECTOR ALIGNED
        do i =  1,2
!
!     update
!
          if(t(i,k).le.t0c) then
            work2(i,k)=-(prevp(i,k)+psdep(i,k)+pgdep(i,k)+pigen(i,k)+pidep(i,k))
            q(i,k) = q(i,k)+work2(i,k)*dtcld
            qci(i,k,1) = max(qci(i,k,1)-(praut(i,k)+pracw(i,k)                 &
                           +paacw(i,k)+paacw(i,k))*dtcld,0.)
            qrs(i,k,1) = max(qrs(i,k,1)+(praut(i,k)+pracw(i,k)                 &
                           +prevp(i,k)-piacr(i,k)-pgacr(i,k)                   &
                           -psacr(i,k))*dtcld,0.)
            qci(i,k,2) = max(qci(i,k,2)-(psaut(i,k)+praci(i,k)                 &
                           +psaci(i,k)+pgaci(i,k)-pigen(i,k)-pidep(i,k))       &
                           *dtcld,0.)
            qrs(i,k,2) = max(qrs(i,k,2)+(psdep(i,k)+psaut(i,k)+paacw(i,k)      &
                           -pgaut(i,k)+piacr(i,k)*delta3(i,k)                  &
                           +praci(i,k)*delta3(i,k)+psaci(i,k)-pgacs(i,k)       &
                           -pracs(i,k)*(1.-delta2(i,k))+psacr(i,k)*delta2(i,k))&
                           *dtcld,0.)
            qrs(i,k,3) = max(qrs(i,k,3)+(pgdep(i,k)+pgaut(i,k)                 &
                           +piacr(i,k)*(1.-delta3(i,k))                        &
                           +praci(i,k)*(1.-delta3(i,k))                        &
                           +psacr(i,k)*(1.-delta2(i,k))                        &
                           +pracs(i,k)*(1.-delta2(i,k))+pgaci(i,k)+paacw(i,k)  &
                           +pgacr(i,k)+pgacs(i,k))*dtcld,0.)
            xlf = xls-xl(i,k)
            xlwork2 = -xls*(psdep(i,k)+pgdep(i,k)+pidep(i,k)+pigen(i,k))       &
                      -xl(i,k)*prevp(i,k)-xlf*(piacr(i,k)+paacw(i,k)           &
                      +paacw(i,k)+pgacr(i,k)+psacr(i,k))
            t(i,k) = t(i,k)-xlwork2/cpm(i,k)*dtcld
          else
            work2(i,k)=-(prevp(i,k)+psevp(i,k)+pgevp(i,k))
            q(i,k) = q(i,k)+work2(i,k)*dtcld
            qci(i,k,1) = max(qci(i,k,1)-(praut(i,k)+pracw(i,k)                 &
                    +paacw(i,k)+paacw(i,k))*dtcld,0.)
            qrs(i,k,1) = max(qrs(i,k,1)+(praut(i,k)+pracw(i,k)                 &
                    +prevp(i,k)+paacw(i,k)+paacw(i,k)-pseml(i,k)               &
                    -pgeml(i,k))*dtcld,0.)
            qrs(i,k,2) = max(qrs(i,k,2)+(psevp(i,k)-pgacs(i,k)                 &
                    +pseml(i,k))*dtcld,0.)
            qrs(i,k,3) = max(qrs(i,k,3)+(pgacs(i,k)+pgevp(i,k)                 &
                    +pgeml(i,k))*dtcld,0.)
            xlf = xls-xl(i,k)
            xlwork2 = -xl(i,k)*(prevp(i,k)+psevp(i,k)+pgevp(i,k))              &
                      -xlf*(pseml(i,k)+pgeml(i,k))
            t(i,k) = t(i,k)-xlwork2/cpm(i,k)*dtcld
          endif
        enddo
      enddo
!
! Inline expansion for fpvs
!         qs(i,k,1) = fpvs(t(i,k),0,rd,rv,cpv,cliq,cice,xlv0,xls,psat,t0c)
!         qs(i,k,2) = fpvs(t(i,k),1,rd,rv,cpv,cliq,cice,xlv0,xls,psat,t0c)
      hsub = xls
      hvap = xlv0
      cvap = cpv
      ttp=t0c+0.01
      dldt=cvap-cliq
      xa=-dldt/rv
      xb=xa+hvap/(rv*ttp)
      dldti=cvap-cice
      xai=-dldti/rv
      xbi=xai+hsub/(rv*ttp)
      do k =  1,32
        do i =  1,2
          tr=ttp/t(i,k)
          qs(i,k,1)=psat*exp(log(tr)*(xa))*exp(xb*(1.-tr))
          qs(i,k,1) = min(qs(i,k,1),0.99*p(i,k))
          qs(i,k,1) = ep2 * qs(i,k,1) / (p(i,k) - qs(i,k,1))
          qs(i,k,1) = max(qs(i,k,1),qmin)
          tr=ttp/t(i,k)
          if(t(i,k).lt.ttp) then
            qs(i,k,2)=psat*exp(log(tr)*(xai))*exp(xbi*(1.-tr))
          else
            qs(i,k,2)=psat*exp(log(tr)*(xa))*exp(xb*(1.-tr))
          endif
          qs(i,k,2) = min(qs(i,k,2),0.99*p(i,k))
          qs(i,k,2) = ep2 * qs(i,k,2) / (p(i,k) - qs(i,k,2))
          qs(i,k,2) = max(qs(i,k,2),qmin)
        enddo
      enddo
!
!----------------------------------------------------------------
!  pcond: condensational/evaporational rate of cloud water [HL A46] [RH83 A6]
!     if there exists additional water vapor condensated/if
!     evaporation of cloud water is not enough to remove subsaturation
!
      do k =  1,32
        do i =  1,2
          work1(i,k,1) = conden(t(i,k),q(i,k),qs(i,k,1),xl(i,k),cpm(i,k))
          work2(i,k) = qci(i,k,1)+work1(i,k,1)
          pcond(i,k) = min(max(work1(i,k,1)/dtcld,0.),max(q(i,k),0.)/dtcld)
          if(qci(i,k,1).gt.0..and.work1(i,k,1).lt.0.)                          &
            pcond(i,k) = max(work1(i,k,1),-qci(i,k,1))/dtcld
          q(i,k) = q(i,k)-pcond(i,k)*dtcld
          qci(i,k,1) = max(qci(i,k,1)+pcond(i,k)*dtcld,0.)
          t(i,k) = t(i,k)+pcond(i,k)*xl(i,k)/cpm(i,k)*dtcld
        enddo
      enddo
!
!
!----------------------------------------------------------------
!     padding for small values
!
      do k =  1,32
!DIR$ VECTOR ALIGNED
        do i =  1,2
          if(qci(i,k,1).le.qmin) qci(i,k,1) = 0.0
          if(qci(i,k,2).le.qmin) qci(i,k,2) = 0.0
        enddo
      enddo
      enddo                  ! big loops
  END SUBROUTINE wsm62d
!--------------------------------------------------------------------------
      subroutine slope_wsm6(qrs,den,denfac,t,rslope,rslopeb,rslope2,rslope3,   &
                            vt,its,ite,kts,kte)
  IMPLICIT NONE
  INTEGER       ::               its,ite, jts,jte, kts,kte
  REAL, DIMENSION( 1:2 , 1:32,3) ::                                     &
                                                                          qrs, &
                                                                       rslope, &
                                                                      rslopeb, &                                                 
                                                                      rslope2, &                                                 
                                                                      rslope3, &                                                 
                                                                           vt
  REAL, DIMENSION( 1:2 , 1:32) ::                                       &
                                                                          den, &
                                                                       denfac, &
                                                                            t
  REAL, PARAMETER  :: t0c = 273.15
  REAL, DIMENSION( 1:2 , 1:32 ) ::                                      &
                                                                       n0sfac
  REAL       ::  lamdar, lamdas, lamdag, x, y, z, supcol
  integer :: i, j, k
!----------------------------------------------------------------
!     size distributions: (x=mixing ratio, y=air density):
!     valid for mixing ratio > 1.e-9 kg/kg.
      lamdar(x,y)=   sqrt(sqrt(pidn0r/(x*y)))      ! (pidn0r/(x*y))**.25
      lamdas(x,y,z)= sqrt(sqrt(pidn0s*z/(x*y)))    ! (pidn0s*z/(x*y))**.25
      lamdag(x,y)=   sqrt(sqrt(pidn0g/(x*y)))      ! (pidn0g/(x*y))**.25
!
!DIR$ ASSUME_ALIGNED qrs:64,den:64,denfac:64,t:64,rslope:64,rslopeb:64,rslope2:64,rslope3:64,vt:64
      do k =  1,32
!DIR$ VECTOR ALIGNED
        do i =  1,2
          supcol = t0c-t(i,k)
!---------------------------------------------------------------
! n0s: Intercept parameter for snow [m-4] [HDC 6]
!---------------------------------------------------------------
          n0sfac(i,k) = max(min(exp(alpha*supcol),n0smax/n0s),1.)
          if(qrs(i,k,1).le.qcrmin)then
            rslope(i,k,1) = rslopermax
            rslopeb(i,k,1) = rsloperbmax
            rslope2(i,k,1) = rsloper2max
            rslope3(i,k,1) = rsloper3max
          else
            rslope(i,k,1) = 1./lamdar(qrs(i,k,1),den(i,k))
            rslopeb(i,k,1) = rslope(i,k,1)**bvtr
            rslope2(i,k,1) = rslope(i,k,1)*rslope(i,k,1)
            rslope3(i,k,1) = rslope2(i,k,1)*rslope(i,k,1)
          endif
          if(qrs(i,k,2).le.qcrmin)then
            rslope(i,k,2) = rslopesmax
            rslopeb(i,k,2) = rslopesbmax
            rslope2(i,k,2) = rslopes2max
            rslope3(i,k,2) = rslopes3max
          else
            rslope(i,k,2) = 1./lamdas(qrs(i,k,2),den(i,k),n0sfac(i,k))
            rslopeb(i,k,2) = rslope(i,k,2)**bvts
            rslope2(i,k,2) = rslope(i,k,2)*rslope(i,k,2)
            rslope3(i,k,2) = rslope2(i,k,2)*rslope(i,k,2)
          endif
          if(qrs(i,k,3).le.qcrmin)then
            rslope(i,k,3) = rslopegmax
            rslopeb(i,k,3) = rslopegbmax
            rslope2(i,k,3) = rslopeg2max
            rslope3(i,k,3) = rslopeg3max
          else
            rslope(i,k,3) = 1./lamdag(qrs(i,k,3),den(i,k))
            rslopeb(i,k,3) = rslope(i,k,3)**bvtg
            rslope2(i,k,3) = rslope(i,k,3)*rslope(i,k,3)
            rslope3(i,k,3) = rslope2(i,k,3)*rslope(i,k,3)
          endif
          vt(i,k,1) = pvtr*rslopeb(i,k,1)*denfac(i,k)
          vt(i,k,2) = pvts*rslopeb(i,k,2)*denfac(i,k)
          vt(i,k,3) = pvtg*rslopeb(i,k,3)*denfac(i,k)
          if(qrs(i,k,1).le.0.0) vt(i,k,1) = 0.0
          if(qrs(i,k,2).le.0.0) vt(i,k,2) = 0.0
          if(qrs(i,k,3).le.0.0) vt(i,k,3) = 0.0
        enddo
      enddo
  END subroutine slope_wsm6
!-----------------------------------------------------------------------------
      subroutine slope_rain(qrs,den,denfac,t,rslope,rslopeb,rslope2,rslope3,   & 
                            vt,kts,kte)
  IMPLICIT NONE
  INTEGER       ::               kts,kte
  REAL, DIMENSION( 1:32) ::                                                 &
                                                                          qrs, &
                                                                       rslope, &
                                                                      rslopeb, &
                                                                      rslope2, &
                                                                      rslope3, &
                                                                           vt, &      
                                                                          den, &
                                                                       denfac, &
                                                                            t
  REAL, PARAMETER  :: t0c = 273.15
  REAL, DIMENSION( 1:32 ) ::                                                &
                                                                       n0sfac
  REAL       ::  lamdar, x, y, z, supcol
  integer :: k
!----------------------------------------------------------------
!     size distributions: (x=mixing ratio, y=air density):
!     valid for mixing ratio > 1.e-9 kg/kg.
      lamdar(x,y)=   sqrt(sqrt(pidn0r/(x*y)))      ! (pidn0r/(x*y))**.25
!
!DIR$ ASSUME_ALIGNED qrs:64,den:64,denfac:64,t:64,rslope:64,rslopeb:64,rslope2:64,rslope3:64,vt:64
!DIR$ VECTOR ALIGNED
      do k =  1,32
          if(qrs(k).le.qcrmin)then
            rslope(k) = rslopermax
            rslopeb(k) = rsloperbmax
            rslope2(k) = rsloper2max
            rslope3(k) = rsloper3max
          else
            rslope(k) = 1./lamdar(qrs(k),den(k))
            rslopeb(k) = rslope(k)**bvtr
            rslope2(k) = rslope(k)*rslope(k)
            rslope3(k) = rslope2(k)*rslope(k)
          endif
          vt(k) = pvtr*rslopeb(k)*denfac(k)
          if(qrs(k).le.0.0) vt(k) = 0.0
      enddo
  END subroutine slope_rain
!------------------------------------------------------------------------------
      subroutine slope_snow(qrs,den,denfac,t,rslope,rslopeb,rslope2,rslope3,   &
                            vt,kts,kte)
  IMPLICIT NONE
  INTEGER       ::               kts,kte
  REAL, DIMENSION( 1:32) ::                                                 &
                                                                          qrs, &
                                                                       rslope, &
                                                                      rslopeb, &
                                                                      rslope2, &
                                                                      rslope3, &
                                                                           vt, &  
                                                                          den, &
                                                                       denfac, &
                                                                            t
  REAL, PARAMETER  :: t0c = 273.15
  REAL, DIMENSION( 1:32 ) ::                                                &
                                                                       n0sfac
  REAL       ::  lamdas, x, y, z, supcol
  integer :: k
!----------------------------------------------------------------
!     size distributions: (x=mixing ratio, y=air density):
!     valid for mixing ratio > 1.e-9 kg/kg.
      lamdas(x,y,z)= sqrt(sqrt(pidn0s*z/(x*y)))    ! (pidn0s*z/(x*y))**.25
!
!DIR$ ASSUME_ALIGNED qrs:64,den:64,denfac:64,t:64,rslope:64,rslopeb:64,rslope2:64,rslope3:64,vt:64
!DIR$ VECTOR ALIGNED
      do k =  1,32
          supcol = t0c-t(k)
!---------------------------------------------------------------
! n0s: Intercept parameter for snow [m-4] [HDC 6]
!---------------------------------------------------------------
          n0sfac(k) = max(min(exp(alpha*supcol),n0smax/n0s),1.)
          if(qrs(k).le.qcrmin)then
            rslope(k) = rslopesmax
            rslopeb(k) = rslopesbmax
            rslope2(k) = rslopes2max
            rslope3(k) = rslopes3max
          else
            rslope(k) = 1./lamdas(qrs(k),den(k),n0sfac(k))
            rslopeb(k) = rslope(k)**bvts
            rslope2(k) = rslope(k)*rslope(k)
            rslope3(k) = rslope2(k)*rslope(k)
          endif
          vt(k) = pvts*rslopeb(k)*denfac(k)
          if(qrs(k).le.0.0) vt(k) = 0.0
      enddo
  END subroutine slope_snow
!----------------------------------------------------------------------------------
      subroutine slope_graup(qrs,den,denfac,t,rslope,rslopeb,rslope2,rslope3,  &
                            vt,kts,kte)
  IMPLICIT NONE
  INTEGER       :: kts,kte
  REAL, DIMENSION( 1:32) ::                                                 &
                                                                          qrs, &
                                                                       rslope, &
                                                                      rslopeb, &
                                                                      rslope2, &
                                                                      rslope3, &
                                                                           vt, &  
                                                                          den, &
                                                                       denfac, &
                                                                            t
  REAL, PARAMETER  :: t0c = 273.15
  REAL, DIMENSION( 1:32 ) ::                                                &
                                                                       n0sfac
  REAL       ::  lamdag, x, y, z, supcol
  integer :: j, k
!----------------------------------------------------------------
!     size distributions: (x=mixing ratio, y=air density):
!     valid for mixing ratio > 1.e-9 kg/kg.
      lamdag(x,y)=   sqrt(sqrt(pidn0g/(x*y)))      ! (pidn0g/(x*y))**.25
!
!DIR$ ASSUME_ALIGNED qrs:64,den:64,denfac:64,t:64,rslope:64,rslopeb:64,rslope2:64,rslope3:64,vt:64
!DIR$ VECTOR ALIGNED
      do k =  1,32
!---------------------------------------------------------------
! n0s: Intercept parameter for snow [m-4] [HDC 6]
!---------------------------------------------------------------
          if(qrs(k).le.qcrmin)then
            rslope(k) = rslopegmax
            rslopeb(k) = rslopegbmax
            rslope2(k) = rslopeg2max
            rslope3(k) = rslopeg3max
          else
            rslope(k) = 1./lamdag(qrs(k),den(k))
            rslopeb(k) = rslope(k)**bvtg
            rslope2(k) = rslope(k)*rslope(k)
            rslope3(k) = rslope2(k)*rslope(k)
          endif
          vt(k) = pvtg*rslopeb(k)*denfac(k)
          if(qrs(k).le.0.0) vt(k) = 0.0
      enddo
  END subroutine slope_graup
!---------------------------------------------------------------------------------
!-------------------------------------------------------------------
      SUBROUTINE nislfv_rain_plm(its,ite,kts,kte,denl,denfacl,tkl,dzl,wwl,rql,precip,dt,id,iter)
!-------------------------------------------------------------------
!
! for non-iteration semi-Lagrangain forward advection for cloud
! with mass conservation and positive definite advection
! 2nd order interpolation with monotonic piecewise linear method
! this routine is under assumption of decfl < 1 for semi_Lagrangian
!
! dzl    depth of model layer in meter
! wwl    terminal velocity at model layer m/s
! rql    cloud density*mixing ration
! precip precipitation
! dt     time step
! id     kind of precip: 0 test case; 1 raindrop
! iter   how many time to guess mean terminal velocity: 0 pure forward.
!        0 : use departure wind for advection
!        1 : use mean wind for advection
!        > 1 : use mean wind after iter-1 iterations
!
! author: hann-ming henry juang <henry.juang@noaa.gov>
!         implemented by song-you hong
!
      implicit none
      integer  its,ite,kts,kte,id
      real  dt
      real  dzl(1:2,1:32),wwl(1:2,1:32),rql(1:2,1:32),precip(1:2)
      real  denl(1:2,1:32),denfacl(1:2,1:32),tkl(1:2,1:32)
!
      integer  i,k,n,m,kk,kb,kt,iter
      real  tl,tl2,qql,dql,qqd
      real  th,th2,qqh,dqh
      real  zsum,qsum,dim,dip,c1,con1,fa1,fa2
      real  allold, allnew, zz, dzamin, cflmax, decfl
      real  dz(1:32), ww(1:32), qq(1:32), wd(1:32), wa(1:32), was(1:32)
      real  den(1:32), denfac(1:32), tk(1:32)
      real  wi(1:32+1), zi(1:32+1), za(1:32+1)
      real  qn(1:32), qr(1:32),tmp(1:32),tmp1(1:32),tmp2(1:32),tmp3(1:32)
      real  dza(1:32+1), qa(1:32+1), qmi(1:32+1), qpi(1:32+1)
!
!DIR$ ASSUME_ALIGNED denl:64,denfacl:64,tkl:64,dzl:64,wwl:64,rql:64,precip:64
      precip(:) = 0.0
!
      i_loop : do i= 1,2
! -----------------------------------
      dz(:) = dzl(i,:)
      qq(:) = rql(i,:)
      ww(:) = wwl(i,:)
      den(:) = denl(i,:)
      denfac(:) = denfacl(i,:)
      tk(:) = tkl(i,:)
! skip for no precipitation for all layers
      allold = 0.0
      do k= 1,32
        allold = allold + qq(k)
      enddo
      if(allold.le.0.0) then
        cycle i_loop
      endif
!
! compute interface values
      zi(kts)=0.0
      do k= 1,32
        zi(k+1) = zi(k)+dz(k)
      enddo
!
! save departure wind
      wd(:) = ww(:)
      n=1
 100  continue
! plm is 2nd order, we can use 2nd order wi or 3rd order wi
! 2nd order interpolation to get wi
      wi(kts) = ww(kts)
      wi(kte+1) = ww(kte)
      do k=kts+1,kte
        wi(k) = (ww(k)*dz(k-1)+ww(k-1)*dz(k))/(dz(k-1)+dz(k))
      enddo
! 3rd order interpolation to get wi
      fa1 = 9./16.
      fa2 = 1./16.
      wi(kts) = ww(kts)
      wi(kts+1) = 0.5*(ww(kts+1)+ww(kts))
      do k=kts+2,kte-1
        wi(k) = fa1*(ww(k)+ww(k-1))-fa2*(ww(k+1)+ww(k-2))
      enddo
      wi(kte) = 0.5*(ww(kte)+ww(kte-1))
      wi(kte+1) = ww(kte)
!
! terminate of top of raingroup
      do k=kts+1,kte
        if( ww(k).eq.0.0 ) wi(k)=ww(k-1)
      enddo
!
! diffusivity of wi
      con1 = 0.05
      do k= 32,1,-1
        decfl = (wi(k+1)-wi(k))*dt/dz(k)
        if( decfl .gt. con1 ) then
          wi(k) = wi(k+1) - con1*dz(k)/dt
        endif
      enddo
! compute arrival point
      do k= 1,32+1
        za(k) = zi(k) - wi(k)*dt
      enddo
!
      do k= 1,32
        dza(k) = za(k+1)-za(k)
      enddo
      dza(kte+1) = zi(kte+1) - za(kte+1)
!
! computer deformation at arrival point
      do k= 1,32
        qa(k) = qq(k)*dz(k)/dza(k)
        qr(k) = qa(k)/den(k)
      enddo
      qa(kte+1) = 0.0
!     call maxmin(kte-kts+1,1,qa,' arrival points ')
!
! compute arrival terminal velocity, and estimate mean terminal velocity
! then back to use mean terminal velocity
      if( n.le.iter ) then
        call slope_rain(qr,den,denfac,tk,tmp,tmp1,tmp2,tmp3,wa,kts,kte)
        if( n.ge.2 ) wa(1:32)=0.5*(wa(1:32)+was(1:32))
        do k= 1,32
!#ifdef DEBUG
!        print*,' slope_wsm3 ',qr(k)*1000.,den(k),denfac(k),tk(k),tmp(k),tmp1(k),tmp2(k),ww(k),wa(k)
!#endif
! mean wind is average of departure and new arrival winds
          ww(k) = 0.5* ( wd(k)+wa(k) )
        enddo
        was(:) = wa(:)
        n=n+1
        go to 100
      endif
!
! estimate values at arrival cell interface with monotone
      do k=kts+1,kte
        dip=(qa(k+1)-qa(k))/(dza(k+1)+dza(k))
        dim=(qa(k)-qa(k-1))/(dza(k-1)+dza(k))
        if( dip*dim.le.0.0 ) then
          qmi(k)=qa(k)
          qpi(k)=qa(k)
        else
          qpi(k)=qa(k)+0.5*(dip+dim)*dza(k)
          qmi(k)=2.0*qa(k)-qpi(k)
          if( qpi(k).lt.0.0 .or. qmi(k).lt.0.0 ) then
            qpi(k) = qa(k)
            qmi(k) = qa(k)
          endif
        endif
      enddo
      qpi(kts)=qa(kts)
      qmi(kts)=qa(kts)
      qmi(kte+1)=qa(kte+1)
      qpi(kte+1)=qa(kte+1)
!
! interpolation to regular point
      qn = 0.0
      kb=kts
      kt=kts
      intp : do k= 1,32
             kb=max(kb-1,kts)
             kt=max(kt-1,kts)
! find kb and kt
             if( zi(k).ge.za(kte+1) ) then
               exit intp
             else
               find_kb : do kk=kb,kte
                         if( zi(k).le.za(kk+1) ) then
                           kb = kk
                           exit find_kb
                         else
                           cycle find_kb
                         endif
               enddo find_kb
               find_kt : do kk=kt,kte
                         if( zi(k+1).le.za(kk) ) then
                           kt = kk
                           exit find_kt
                         else
                           cycle find_kt
                         endif
               enddo find_kt
               kt = kt - 1
! compute q with piecewise constant method
               if( kt.eq.kb ) then
                 tl=(zi(k)-za(kb))/dza(kb)
                 th=(zi(k+1)-za(kb))/dza(kb)
                 tl2=tl*tl
                 th2=th*th
                 qqd=0.5*(qpi(kb)-qmi(kb))
                 qqh=qqd*th2+qmi(kb)*th
                 qql=qqd*tl2+qmi(kb)*tl
                 qn(k) = (qqh-qql)/(th-tl)
               else if( kt.gt.kb ) then
                 tl=(zi(k)-za(kb))/dza(kb)
                 tl2=tl*tl
                 qqd=0.5*(qpi(kb)-qmi(kb))
                 qql=qqd*tl2+qmi(kb)*tl
                 dql = qa(kb)-qql
                 zsum  = (1.-tl)*dza(kb)
                 qsum  = dql*dza(kb)
                 if( kt-kb.gt.1 ) then
                 do m=kb+1,kt-1
                   zsum = zsum + dza(m)
                   qsum = qsum + qa(m) * dza(m)
                 enddo
                 endif
                 th=(zi(k+1)-za(kt))/dza(kt)
                 th2=th*th
                 qqd=0.5*(qpi(kt)-qmi(kt))
                 dqh=qqd*th2+qmi(kt)*th
                 zsum  = zsum + th*dza(kt)
                 qsum  = qsum + dqh*dza(kt)
                 qn(k) = qsum/zsum
               endif
               cycle intp
             endif
!
       enddo intp
!
! rain out
      sum_precip: do k= 1,32
                    if( za(k).lt.0.0 .and. za(k+1).lt.0.0 ) then
                      precip(i) = precip(i) + qa(k)*dza(k)
                      cycle sum_precip
                    else if ( za(k).lt.0.0 .and. za(k+1).ge.0.0 ) then
                      precip(i) = precip(i) + qa(k)*(0.0-za(k))
                      exit sum_precip
                    endif
                    exit sum_precip
      enddo sum_precip
!
! replace the new values
!DIR$ VECTOR ALIGNED
      rql(i,:) = qn(:)
!
! ----------------------------------
      enddo i_loop
!
  END SUBROUTINE nislfv_rain_plm
!-------------------------------------------------------------------
      SUBROUTINE nislfv_rain_plm6(its,ite,kts,kte,denl,denfacl,tkl,dzl,wwl,rql,rql2, precip1, precip2,dt,id,iter)
!-------------------------------------------------------------------
!
! for non-iteration semi-Lagrangain forward advection for cloud
! with mass conservation and positive definite advection
! 2nd order interpolation with monotonic piecewise linear method
! this routine is under assumption of decfl < 1 for semi_Lagrangian
!
! dzl    depth of model layer in meter
! wwl    terminal velocity at model layer m/s
! rql    cloud density*mixing ration
! precip precipitation
! dt     time step
! id     kind of precip: 0 test case; 1 raindrop
! iter   how many time to guess mean terminal velocity: 0 pure forward.
!        0 : use departure wind for advection
!        1 : use mean wind for advection
!        > 1 : use mean wind after iter-1 iterations
!
! author: hann-ming henry juang <henry.juang@noaa.gov>
!         implemented by song-you hong
!
      implicit none
      integer  its,ite,kts,kte,id
      real  dt
      real  dzl(1:2,1:32),wwl(1:2,1:32),rql(1:2,1:32),rql2(1:2,1:32),precip(1:2),precip1(1:2),precip2(1:2)
      real  denl(1:2,1:32),denfacl(1:2,1:32),tkl(1:2,1:32)
!
      integer  i,k,n,m,kk,kb,kt,iter,ist
      real  tl,tl2,qql,dql,qqd
      real  th,th2,qqh,dqh
      real  zsum,qsum,dim,dip,c1,con1,fa1,fa2
      real  allold, allnew, zz, dzamin, cflmax, decfl
      real  dz(1:32), ww(1:32), qq(1:32), qq2(1:32), wd(1:32), wa(1:32), wa2(1:32), was(1:32)
      real  den(1:32), denfac(1:32), tk(1:32)
      real  wi(1:32+1), zi(1:32+1), za(1:32+1)
      real  qn(1:32), qr(1:32),qr2(1:32),tmp(1:32),tmp1(1:32),tmp2(1:32),tmp3(1:32)
      real  dza(1:32+1), qa(1:32+1), qa2(1:32+1),qmi(1:32+1), qpi(1:32+1)
!
!DIR$ ASSUME_ALIGNED denl:64,denfacl:64,tkl:64,dzl:64,wwl:64,rql:64,rql2:64,precip1:64,precip2:64
      precip(:) = 0.0
      precip1(:) = 0.0
      precip2(:) = 0.0
!
      i_loop : do i= 1,2
! -----------------------------------
      dz(:) = dzl(i,:)
      qq(:) = rql(i,:)
      qq2(:) = rql2(i,:)
      ww(:) = wwl(i,:)
      den(:) = denl(i,:)
      denfac(:) = denfacl(i,:)
      tk(:) = tkl(i,:)
! skip for no precipitation for all layers
      allold = 0.0
      do k= 1,32
        allold = allold + qq(k)
      enddo
      if(allold.le.0.0) then
        cycle i_loop
      endif
!
! compute interface values
      zi(kts)=0.0
      do k= 1,32
        zi(k+1) = zi(k)+dz(k)
      enddo
!
! save departure wind
      wd(:) = ww(:)
      n=1
 100  continue
! plm is 2nd order, we can use 2nd order wi or 3rd order wi
! 2nd order interpolation to get wi
      wi(kts) = ww(kts)
      wi(kte+1) = ww(kte)
      do k=kts+1,kte
        wi(k) = (ww(k)*dz(k-1)+ww(k-1)*dz(k))/(dz(k-1)+dz(k))
      enddo
! 3rd order interpolation to get wi
      fa1 = 9./16.
      fa2 = 1./16.
      wi(kts) = ww(kts)
      wi(kts+1) = 0.5*(ww(kts+1)+ww(kts))
      do k=kts+2,kte-1
        wi(k) = fa1*(ww(k)+ww(k-1))-fa2*(ww(k+1)+ww(k-2))
      enddo
      wi(kte) = 0.5*(ww(kte)+ww(kte-1))
      wi(kte+1) = ww(kte)
!
! terminate of top of raingroup
      do k=kts+1,kte
        if( ww(k).eq.0.0 ) wi(k)=ww(k-1)
      enddo
!
! diffusivity of wi
      con1 = 0.05
      do k= 32,1,-1
        decfl = (wi(k+1)-wi(k))*dt/dz(k)
        if( decfl .gt. con1 ) then
          wi(k) = wi(k+1) - con1*dz(k)/dt
        endif
      enddo
! compute arrival point
      do k= 1,32+1
        za(k) = zi(k) - wi(k)*dt
      enddo
!
      do k= 1,32
        dza(k) = za(k+1)-za(k)
      enddo
      dza(kte+1) = zi(kte+1) - za(kte+1)
!
! computer deformation at arrival point
      do k= 1,32
        qa(k) = qq(k)*dz(k)/dza(k)
        qa2(k) = qq2(k)*dz(k)/dza(k)
        qr(k) = qa(k)/den(k)
        qr2(k) = qa2(k)/den(k)
      enddo
      qa(kte+1) = 0.0
      qa2(kte+1) = 0.0
!     call maxmin(kte-kts+1,1,qa,' arrival points ')
!
! compute arrival terminal velocity, and estimate mean terminal velocity
! then back to use mean terminal velocity
      if( n.le.iter ) then
        call slope_snow(qr,den,denfac,tk,tmp,tmp1,tmp2,tmp3,wa,kts,kte)
        call slope_graup(qr2,den,denfac,tk,tmp,tmp1,tmp2,tmp3,wa2,kts,kte)
        do k =  1,32
          tmp(k) = max((qr(k)+qr2(k)), 1.E-15)
          IF ( tmp(k) .gt. 1.e-15 ) THEN
            wa(k) = (wa(k)*qr(k) + wa2(k)*qr2(k))/tmp(k)
          ELSE
            wa(k) = 0.
          ENDIF
        enddo
        if( n.ge.2 ) wa(1:32)=0.5*(wa(1:32)+was(1:32))
        do k= 1,32
!#ifdef DEBUG
!        print*,' slope_wsm3 ',qr(k)*1000.,den(k),denfac(k),tk(k),tmp(k),tmp1(k),tmp2(k), &
!           ww(k),wa(k)
!#endif
! mean wind is average of departure and new arrival winds
          ww(k) = 0.5* ( wd(k)+wa(k) )
        enddo
        was(:) = wa(:)
        n=n+1
        go to 100
      endif
      ist_loop : do ist = 1, 2
      if (ist.eq.2) then
       qa(:) = qa2(:)
      endif
!
      precip(i) = 0.
!
! estimate values at arrival cell interface with monotone
      do k=kts+1,kte
        dip=(qa(k+1)-qa(k))/(dza(k+1)+dza(k))
        dim=(qa(k)-qa(k-1))/(dza(k-1)+dza(k))
        if( dip*dim.le.0.0 ) then
          qmi(k)=qa(k)
          qpi(k)=qa(k)
        else
          qpi(k)=qa(k)+0.5*(dip+dim)*dza(k)
          qmi(k)=2.0*qa(k)-qpi(k)
          if( qpi(k).lt.0.0 .or. qmi(k).lt.0.0 ) then
            qpi(k) = qa(k)
            qmi(k) = qa(k)
          endif
        endif
      enddo
      qpi(kts)=qa(kts)
      qmi(kts)=qa(kts)
      qmi(kte+1)=qa(kte+1)
      qpi(kte+1)=qa(kte+1)
!
! interpolation to regular point
      qn = 0.0
      kb=kts
      kt=kts
      intp : do k= 1,32
             kb=max(kb-1,kts)
             kt=max(kt-1,kts)
! find kb and kt
             if( zi(k).ge.za(kte+1) ) then
               exit intp
             else
               find_kb : do kk=kb,kte
                         if( zi(k).le.za(kk+1) ) then
                           kb = kk
                           exit find_kb
                         else
                           cycle find_kb
                         endif
               enddo find_kb
               find_kt : do kk=kt,kte
                         if( zi(k+1).le.za(kk) ) then
                           kt = kk
                           exit find_kt
                         else
                           cycle find_kt
                         endif
               enddo find_kt
               kt = kt - 1
! compute q with piecewise constant method
               if( kt.eq.kb ) then
                 tl=(zi(k)-za(kb))/dza(kb)
                 th=(zi(k+1)-za(kb))/dza(kb)
                 tl2=tl*tl
                 th2=th*th
                 qqd=0.5*(qpi(kb)-qmi(kb))
                 qqh=qqd*th2+qmi(kb)*th
                 qql=qqd*tl2+qmi(kb)*tl
                 qn(k) = (qqh-qql)/(th-tl)
               else if( kt.gt.kb ) then
                 tl=(zi(k)-za(kb))/dza(kb)
                 tl2=tl*tl
                 qqd=0.5*(qpi(kb)-qmi(kb))
                 qql=qqd*tl2+qmi(kb)*tl
                 dql = qa(kb)-qql
                 zsum  = (1.-tl)*dza(kb)
                 qsum  = dql*dza(kb)
                 if( kt-kb.gt.1 ) then
                 do m=kb+1,kt-1
                   zsum = zsum + dza(m)
                   qsum = qsum + qa(m) * dza(m)
                 enddo
                 endif
                 th=(zi(k+1)-za(kt))/dza(kt)
                 th2=th*th
                 qqd=0.5*(qpi(kt)-qmi(kt))
                 dqh=qqd*th2+qmi(kt)*th
                 zsum  = zsum + th*dza(kt)
                 qsum  = qsum + dqh*dza(kt)
                 qn(k) = qsum/zsum
               endif
               cycle intp
             endif
!
       enddo intp
!
! rain out
      sum_precip: do k= 1,32
                    if( za(k).lt.0.0 .and. za(k+1).lt.0.0 ) then
                      precip(i) = precip(i) + qa(k)*dza(k)
                      cycle sum_precip
                    else if ( za(k).lt.0.0 .and. za(k+1).ge.0.0 ) then
                      precip(i) = precip(i) + qa(k)*(0.0-za(k))
                      exit sum_precip
                    endif
                    exit sum_precip
      enddo sum_precip
!
! replace the new values
      if(ist.eq.1) then
        rql(i,:) = qn(:)
        precip1(i) = precip(i)
      else
        rql2(i,:) = qn(:)
        precip2(i) = precip(i)
      endif
      enddo ist_loop
!
! ----------------------------------
      enddo i_loop
!
  END SUBROUTINE nislfv_rain_plm6
!---------------------------------------------------------------------------------
!+---+-----------------------------------------------------------------+
  ! Read array from unitno and convert from "no-chunk" to "chunk"
  SUBROUTINE readarray2(arr,arrname,unitno,ips,ipe)
    REAL,             INTENT(OUT) :: arr(:,:)
    CHARACTER(LEN=*), INTENT(IN)  :: arrname
    INTEGER,          INTENT(IN)  :: unitno
    INTEGER,          INTENT(IN)  :: ips,ipe
    REAL, ALLOCATABLE :: tmparr(:)
    INTEGER :: i,j,ij,jsize,CHUNK,ipn
    CHUNK = size(arr,1)
    jsize = size(arr,2)
    ALLOCATE(tmparr(ips:ipe))
    read(unitno) tmparr
    print *,' max ',trim(arrname),' = ',maxval(tmparr),' at ',maxloc(tmparr)
    print *,' min ',trim(arrname),' = ',minval(tmparr),' at ',minloc(tmparr)
    do j = 1,jsize
      ij = (j-1)*CHUNK
      do i = 1,CHUNK
        ! replicate last column if needed
        ipn = min(ij+i+ips-1,ipe)
        arr(i,j) = tmparr(ipn)
      enddo
    enddo
    DEALLOCATE(tmparr)
  END SUBROUTINE readarray2

!+---+-----------------------------------------------------------------+
  ! Read array from unitno and convert from "no-chunk" to "chunk"
  SUBROUTINE readarray3(arr,arrname,unitno,ips,ipe)
    REAL,             INTENT(OUT) :: arr(:,:,:)
    CHARACTER(LEN=*), INTENT(IN)  :: arrname
    INTEGER,          INTENT(IN)  :: unitno
    INTEGER,          INTENT(IN)  :: ips,ipe
    REAL, ALLOCATABLE :: tmparr(:,:)
    INTEGER :: i,j,k,ij,ksize,jsize,CHUNK,ipn
    CHUNK = size(arr,1)
    ksize = size(arr,2)
    jsize = size(arr,3)
    ALLOCATE(tmparr(ips:ipe,ksize))
    read(unitno) tmparr
    print *,' max ',trim(arrname),' = ',maxval(tmparr),' at ',maxloc(tmparr)
    print *,' min ',trim(arrname),' = ',minval(tmparr),' at ',minloc(tmparr)
    do j = 1,jsize
      ij = (j-1)*CHUNK
      do i = 1,CHUNK
        ! replicate last column if needed
        ipn = min(ij+i+ips-1,ipe)
        do k = 1,ksize
          arr(i,k,j) = tmparr(ipn,k)
        enddo
      enddo
    enddo
    DEALLOCATE(tmparr)
  END SUBROUTINE readarray3

!+---+-----------------------------------------------------------------+
  ! Read array from unitno and convert from "no-chunk" to "chunk"
  SUBROUTINE readarray4(arr,arrname,unitno,ips,ipe)
    REAL,             INTENT(OUT) :: arr(:,:,:,:)
    CHARACTER(LEN=*), INTENT(IN)  :: arrname
    INTEGER,          INTENT(IN)  :: unitno
    INTEGER,          INTENT(IN)  :: ips,ipe
    REAL, ALLOCATABLE :: tmparr(:,:,:)
    INTEGER :: i,j,k,ij,ksize,jsize,CHUNK,ipn,m,msize
    CHUNK = size(arr,1)
    ksize = size(arr,2)
    msize = size(arr,3)
    jsize = size(arr,4)
    ALLOCATE(tmparr(ips:ipe,ksize,msize))
    read(unitno) tmparr
    print *,' max ',trim(arrname),' = ',maxval(tmparr),' at ',maxloc(tmparr)
    print *,' min ',trim(arrname),' = ',minval(tmparr),' at ',minloc(tmparr)
    do j = 1,jsize
      ij = (j-1)*CHUNK
      do m = 1,msize
        do i = 1,CHUNK
          ! replicate last column if needed
          ipn = min(ij+i+ips-1,ipe)
          do k = 1,ksize
            arr(i,k,m,j) = tmparr(ipn,k,m)
          enddo
        enddo
      enddo
    enddo
    DEALLOCATE(tmparr)
  END SUBROUTINE readarray4

!+---+-----------------------------------------------------------------+
  ! Convert array from "chunk" to "no-chunk" and write to unitno.  
  SUBROUTINE writearray2(arr,arrname,unitno,ips,ipe)
    REAL,             INTENT(IN) :: arr(:,:)
    CHARACTER(LEN=*), INTENT(IN) :: arrname
    INTEGER,          INTENT(IN) :: unitno
    INTEGER,          INTENT(IN) :: ips,ipe
    REAL, ALLOCATABLE :: tmparr(:)
    INTEGER :: i,j,ij,jsize,CHUNK,ipn
    CHUNK = size(arr,1)
    jsize = size(arr,2)
    ALLOCATE(tmparr(ips:ipe))
    do j = 1,jsize
      ij = (j-1)*CHUNK
      do i = 1,CHUNK
        ipn = ij+i+ips-1
        ! skip any replicated columns
        if ((ips<=ipn).and.(ipn<=ipe)) then
          tmparr(ipn) = arr(i,j)
        endif
      enddo
    enddo
    write(unitno) tmparr
    print *,' max ',trim(arrname),' = ',maxval(tmparr),' at ',maxloc(tmparr)
    print *,' min ',trim(arrname),' = ',minval(tmparr),' at ',minloc(tmparr)
    DEALLOCATE(tmparr)
  END SUBROUTINE writearray2

!+---+-----------------------------------------------------------------+
  ! Convert array from "chunk" to "no-chunk" and write to unitno.  
  SUBROUTINE writearray3(arr,arrname,unitno,ips,ipe)
    REAL,             INTENT(IN) :: arr(:,:,:)
    CHARACTER(LEN=*), INTENT(IN) :: arrname
    INTEGER,          INTENT(IN) :: unitno
    INTEGER,          INTENT(IN) :: ips,ipe
    REAL, ALLOCATABLE :: tmparr(:,:)
    INTEGER :: i,j,k,ij,ksize,jsize,CHUNK,ipn
    CHUNK = size(arr,1)
    ksize = size(arr,2)
    jsize = size(arr,3)
    ALLOCATE(tmparr(ips:ipe,ksize))
    do j = 1,jsize
      ij = (j-1)*CHUNK
      do i = 1,CHUNK
        ipn = ij+i+ips-1
        ! skip any replicated columns
        if ((ips<=ipn).and.(ipn<=ipe)) then
          do k = 1,ksize
            tmparr(ipn,k) = arr(i,k,j)
          enddo
        endif
      enddo
    enddo
    write(unitno) tmparr
    print *,' max ',trim(arrname),' = ',maxval(tmparr),' at ',maxloc(tmparr)
    print *,' min ',trim(arrname),' = ',minval(tmparr),' at ',minloc(tmparr)
    DEALLOCATE(tmparr)
  END SUBROUTINE writearray3

!+---+-----------------------------------------------------------------+
  ! Convert array from "chunk" to "no-chunk" and write to unitno.  
  SUBROUTINE writearray4(arr,arrname,unitno,ips,ipe)
    REAL,             INTENT(IN) :: arr(:,:,:,:)
    CHARACTER(LEN=*), INTENT(IN) :: arrname
    INTEGER,          INTENT(IN) :: unitno
    INTEGER,          INTENT(IN) :: ips,ipe
    REAL, ALLOCATABLE :: tmparr(:,:,:)
    INTEGER :: i,j,k,ij,ksize,jsize,CHUNK,ipn,m,msize
    CHUNK = size(arr,1)
    ksize = size(arr,2)
    msize = size(arr,3)
    jsize = size(arr,4)
    ALLOCATE(tmparr(ips:ipe,ksize,msize))
    do j = 1,jsize
      ij = (j-1)*CHUNK
      do m = 1,msize
        do i = 1,CHUNK
          ipn = ij+i+ips-1
          ! skip any replicated columns
          if ((ips<=ipn).and.(ipn<=ipe)) then
            do k = 1,ksize
              tmparr(ipn,k,m) = arr(i,k,m,j)
            enddo
          endif
        enddo
      enddo
    enddo
    write(unitno) tmparr
    print *,' max ',trim(arrname),' = ',maxval(tmparr),' at ',maxloc(tmparr)
    print *,' min ',trim(arrname),' = ',minval(tmparr),' at ',minloc(tmparr)
    DEALLOCATE(tmparr)
  END SUBROUTINE writearray4

  SUBROUTINE firstTouch(t, q                                      &   
                   ,qci, qrs, den, p, delz                        &
                   ,lat                                           &
                   ,rain,rainncv                                  &
                   ,sr                                            &
                   ,ids,ide, jds,jde, kds,kde                     &
                   ,ims,ime, jms,jme, kms,kme                     &
                   ,its,ite, jts,jte, kts,kte                     &
                   ,snow,snowncv                                  &
                   ,graupel,graupelncv                            &
                                                                  )
!-------------------------------------------------------------------
  IMPLICIT NONE
!-------------------------------------------------------------------
!
!  Mimic memory access patterns of wsm62D() while setting physics arrays 
!  to zero.  
!
  INTEGER,      INTENT(IN   )    ::   ids,ide, jds,jde, kds,kde , &
                                      ims,ime, jms,jme, kms,kme , &
                                      its,ite, jts,jte, kts,kte,  &
                                      lat
  REAL, DIMENSION( 1:2 , 1:32 ),                           &
        INTENT(INOUT) ::                                          &
                                                               t
  REAL, DIMENSION( 1:2 , 1:32, 2 ),                        &
        INTENT(INOUT) ::                                          &
                                                             qci
  REAL, DIMENSION( 1:2 , 1:32, 3 ),                        &
        INTENT(INOUT) ::                                          &
                                                             qrs
  REAL, DIMENSION( 1:2 , 1:33 ),                           &
        INTENT(INOUT) ::                                          &
                                                               q
  REAL, DIMENSION( 1:2 , 1:33 ),                           &
        INTENT(INOUT) ::                                          &
                                                             den, &
                                                               p, &
                                                            delz
  REAL, DIMENSION( 1:2 ),                                     &
        INTENT(INOUT) ::                                    rain, &
                                                         rainncv, &
                                                              sr
  REAL, DIMENSION( 1:2, jms:jme ), OPTIONAL,                  &
        INTENT(INOUT) ::                                    snow, &
                                                         snowncv
  REAL, DIMENSION( 1:2, jms:jme ), OPTIONAL,                  &
        INTENT(INOUT) ::                                 graupel, &
                                                      graupelncv
! LOCAL VAR
  INTEGER :: i, k
!
      do k =  1,32
        do i =  1,2
          t(i,k) = 0.
          q(i,k) = 0.
          qci(i,k,1) = 0.
          qci(i,k,2) = 0.
          qrs(i,k,1) = 0.
          qrs(i,k,2) = 0.
          qrs(i,k,3) = 0.
          den(i,k) = 0.
          p(i,k) = 0.
          delz(i,k) = 0.
        enddo
      enddo
      do i =  1,2
        rain(i) = 0.
        rainncv(i) = 0.
        sr(i) = 0.
      enddo
      if (PRESENT(snow)) then
        do i =  1,2
          snow(i,lat) = 0.
        enddo
      endif
      if (PRESENT(snowncv)) then
        do i =  1,2
          snowncv(i,lat) = 0.
        enddo
      endif
      if (PRESENT(graupel)) then
        do i =  1,2
          graupel(i,lat) = 0.
        enddo
      endif
      if (PRESENT(graupelncv)) then
        do i =  1,2
          graupelncv(i,lat) = 0.
        enddo
      endif
  END SUBROUTINE firstTouch

END MODULE module_mp_wsm6




  PROGRAM wsm6
!-------------------------------------------------------------------
  USE module_mp_wsm6
!-------------------------------------------------------------------
  IMPLICIT NONE
!-------------------------------------------------------------------
  INTEGER ::   ids, ide,  jds, jde, kds,kde , &
               ims, ime,  jms, jme, kms,kme , &
               its, ite,  jts, jte, kts,kte
  ! "chunk" indices
  INTEGER ::  iids,iide, jjds,jjde,           &
              iims,iime, jjms,jjme,           &
              iits,iite, jjts,jjte
! timers
!
! $Id: gptl.inc.template,v 1.3 2011-03-28 20:55:19 rosinski Exp $
!
! Author: Jim Rosinski
!
! GPTL header file to be included in user code. Values match
! their counterparts in gptl.h. See that file or man pages
! or web-based documenation for descriptions of each value
!
      integer GPTLsync_mpi
      integer GPTLwall
      integer GPTLcpu
      integer GPTLabort_on_error
      integer GPTLoverhead
      integer GPTLdepthlimit
      integer GPTLverbose
      integer GPTLnarrowprint
      integer GPTLpercent
      integer GPTLpersec
      integer GPTLmultiplex
      integer GPTLdopr_preamble
      integer GPTLdopr_threadsort
      integer GPTLdopr_multparent
      integer GPTLdopr_collision
      integer GPTLdopr_memusage
      integer GPTLprint_method
      integer GPTLtablesize
      integer GPTLmaxthreads

      integer GPTL_IPC
      integer GPTL_CI
      integer GPTL_FPC
      integer GPTL_FPI
      integer GPTL_LSTPI
      integer GPTL_DCMRT
      integer GPTL_LSTPDCM
      integer GPTL_L2MRT
      integer GPTL_LSTPL2M
      integer GPTL_L3MRT

      integer GPTLnanotime
      integer GPTLmpiwtime
      integer GPTLclockgettime
      integer GPTLgettimeofday
      integer GPTLpapitime
      integer GPTLplacebo
      integer GPTLread_real_time

      integer GPTLfirst_parent
      integer GPTLlast_parent
      integer GPTLmost_frequent
      integer GPTLfull_tree

      parameter (GPTLsync_mpi       = 0)
      parameter (GPTLwall           = 1)
      parameter (GPTLcpu            = 2)
      parameter (GPTLabort_on_error = 3)
      parameter (GPTLoverhead       = 4)
      parameter (GPTLdepthlimit     = 5)
      parameter (GPTLverbose        = 6)
      parameter (GPTLnarrowprint    = 7)
      parameter (GPTLpercent        = 9)
      parameter (GPTLpersec         = 10)
      parameter (GPTLmultiplex      = 11)
      parameter (GPTLdopr_preamble  = 12)
      parameter (GPTLdopr_threadsort= 13)
      parameter (GPTLdopr_multparent= 14)
      parameter (GPTLdopr_collision = 15)
      parameter (GPTLdopr_memusage  = 27)
      parameter (GPTLprint_method   = 16)
      parameter (GPTLtablesize      = 50)
      parameter (GPTLmaxthreads     = 51)

      parameter (GPTL_IPC           = 17)
      parameter (GPTL_CI            = 18)
      parameter (GPTL_FPC           = 19)
      parameter (GPTL_FPI           = 20)
      parameter (GPTL_LSTPI         = 21)
      parameter (GPTL_DCMRT         = 22)
      parameter (GPTL_LSTPDCM       = 23)
      parameter (GPTL_L2MRT         = 24)
      parameter (GPTL_LSTPL2M       = 25)
      parameter (GPTL_L3MRT         = 26)

      parameter (GPTLgettimeofday   = 1)
      parameter (GPTLnanotime       = 2)
      parameter (GPTLmpiwtime       = 4)
      parameter (GPTLclockgettime   = 5)
      parameter (GPTLpapitime       = 6)
      parameter (GPTLplacebo        = 7)
      parameter (GPTLread_real_time = 3)

      parameter (GPTLfirst_parent   = 1)
      parameter (GPTLlast_parent    = 2)
      parameter (GPTLmost_frequent  = 3)
      parameter (GPTLfull_tree      = 4)

! Externals

      integer gptlsetoption
      integer gptlinitialize
      integer gptlstart
      integer gptlstart_handle
      integer gptlinit_handle
      integer gptlstop
      integer gptlstop_handle
      integer gptlstamp 
      integer gptlpr
      integer gptlpr_file
      integer gptlpr_summary
      integer gptlpr_summary_file
      integer gptlbarrier
      integer gptlreset 
      integer gptlfinalize
      integer gptlget_memusage
      integer gptlprint_memusage
      integer gptlprint_rusage
      integer gptlenable
      integer gptldisable
      integer gptlsetutr
      integer gptlquery
      integer gptlquerycounters
      integer gptlget_wallclock
      integer gptlget_eventvalue
      integer gptlget_nregions
      integer gptlget_regionname
      integer gptl_papilibraryinit
      integer gptlevent_name_to_code
      integer gptlevent_code_to_name
      integer gptlnum_errors
      integer gptlnum_warn
      integer gptlget_count

      external gptlsetoption
      external gptlinitialize
      external gptlstart
      external gptlstart_handle
      external gptlinit_handle
      external gptlstop
      external gptlstop_handle
      external gptlstamp 
      external gptlpr
      external gptlpr_file
      external gptlpr_summary
      external gptlpr_summary_file
      external gptlbarrier
      external gptlreset 
      external gptlfinalize
      external gptlget_memusage
      external gptlprint_memusage
      external gptlprint_rusage
      external gptlenable
      external gptldisable
      external gptlsetutr
      external gptlquery
      external gptlquerycounters
      external gptlget_wallclock
      external gptlget_eventvalue
      external gptlget_nregions
      external gptlget_regionname
      external gptl_papilibraryinit
      external gptlevent_name_to_code
      external gptlevent_code_to_name
      external gptlnum_errors
      external gptlnum_warn
      external gptlget_count
  INTEGER :: ret
  REAL*8  :: totaltime
  INTEGER :: handle = 0
! Contains definition of _CHUNK_

! Contains definition of _NZ_

  INTEGER :: CHUNK, NZ_BUILD
  INTEGER :: num_tiles_C
  INTEGER ::  itimestep
  REAL, ALLOCATABLE :: t(:,:,:)
  REAL, ALLOCATABLE :: qci(:,:,:,:)
  REAL, ALLOCATABLE :: qrs(:,:,:,:)
  REAL, ALLOCATABLE :: q(:,:,:)
  REAL, ALLOCATABLE :: den(:,:,:)
  REAL, ALLOCATABLE :: p(:,:,:)
  REAL, ALLOCATABLE :: delz(:,:,:)
  REAL :: delt, g, rd, rv, t0c, den0, cpd, cpv, ep1, ep2, qmin, &
          XLS, XLV0, XLF0, cliq, cice, psat, denr
  REAL, ALLOCATABLE :: rain(:,:)
  REAL, ALLOCATABLE :: rainncv(:,:)
  REAL, ALLOCATABLE :: sr(:,:)
  REAL, ALLOCATABLE :: snow(:,:)
  REAL, ALLOCATABLE :: snowncv(:,:)
  REAL, ALLOCATABLE :: graupel(:,:)
  REAL, ALLOCATABLE :: graupelncv(:,:)

!+---+-----------------------------------------------------------------+
! LOCAL VAR
  INTEGER ::               i,j,k
  INTEGER :: ios, unitno
  CHARACTER(LEN=64) :: fn  ! file name

!+---+-----------------------------------------------------------------+
! EXTERNAL FUNCTIONS
  integer, external :: omp_get_max_threads
!+---+-----------------------------------------------------------------+

  call gptlprocess_namelist ('GPTLnamelist', 77, ret)
  ret = gptlinitialize ()
  ret = gptlstart('Total')

  ! read constants
  PRINT *,'wsm6init():  read constants'
  fn = 'wsm6_constants.dat'
  unitno=31
  open (unitno,file=trim(fn),form="unformatted",action='read', &
        iostat=ios)
  if (ios /= 0) then
    write(6,*) 'ERROR: failed to open constant file ',trim(fn), &
               ' . stopping'
    stop
  endif
  read(unitno) pi, xlv1
  read(unitno) qc0, qck1
  read(unitno) bvtr1, bvtr2, bvtr3, bvtr4, bvtr6, g1pbr, g3pbr, &
               g4pbr, g6pbr, g5pbro2, pvtr, eacrr, pacrr, &
               precr1, precr2, roqimax
  read(unitno) bvts1, bvts2, bvts3, bvts4, g1pbs, g3pbs, g4pbs,  &
               g5pbso2, pvts, pacrs, precs1, precs2, pidn0r, pidn0s
  read(unitno) pacrc
  read(unitno) bvtg1, bvtg2, bvtg3, bvtg4, g1pbg, g3pbg, g4pbg,  &
               pacrg, g5pbgo2, pvtg, precg1, precg2, pidn0g
  read(unitno) rslopermax, rslopesmax, rslopegmax, rsloperbmax,  &
               rslopesbmax, rslopegbmax, rsloper2max, rslopes2max,  &
               rslopeg2max, rsloper3max, rslopes3max, rslopeg3max
  close(unitno)

  ! read input data
  PRINT *,'wsm62D():  read input state'
  fn = 'wsm6_input.dat'
  unitno=31
  open (unitno,file=trim(fn),form="unformatted",action='read', &
        iostat=ios)
  if (ios /= 0) then
    write(6,*) 'ERROR: failed to open input file ',trim(fn), &
               ' . stopping'
    stop
  endif
  read(unitno) itimestep
  PRINT *,'wsm62D():  itimestep == ',itimestep
  ! read serial versions of indices
  read(unitno) ids,ide, jds,jde, kds,kde, &
               ims,ime, jms,jme, kms,kme, &
               its,ite, jts,jte, kts,kte

  ! assert constraints on indices
  ! NOTE that [ikj]d[se] are ignored
  if ((ims/=its).or.(ime/=ite).or.(jms/=jts).or.(jme/=jte)) then
    print *,'ERROR:  index mismatch reading file ',trim(fn), &
            ' . stopping'
    stop
  endif
  if ((ims/=1).or.(jms/=1)) then
    print *,'ERROR:  incorrect start index reading file ',trim(fn), &
            ' . stopping'
    stop
  endif

  ! set default values of "chunk" indices
  iids = ids
  iide = ide
  iims = ims
  iime = ime
  iits = its
  iite = ite
  jjds = jds
  jjde = jde
  jjms = jms
  jjme = jme
  jjts = jts
  jjte = jte

  ! set up optional "i" chunking and optional fixed vertical extent
   CHUNK = 2
   NZ_BUILD = 32
   ! if specified, NZ_BUILD must match namelist setting for nvl
   if (NZ_BUILD/=kte-kts+1) then
     print *, 'ERROR:  Build-time-specified NZ must equal namelist nz, values are: ',NZ_BUILD,kte-kts+1
     call flush(6)
     stop
   endif
   num_tiles_C = (iite-iits+1) / CHUNK
   if (mod((iite-iits+1),CHUNK) > 0) then
     num_tiles_C = num_tiles_C + 1
   endif
   iime = CHUNK
   iite = CHUNK
   jjme = num_tiles_C
   jjte = num_tiles_C
   PRINT *,'ims,ime,iims,iime',ims,ime,iims,iime
   PRINT "('omp_get_max_threads() returned:  ',I9)",omp_get_max_threads()
   PRINT *,'CHUNK =', CHUNK
   PRINT *,'NUMBER OF CHUNKS =', num_tiles_C
   PRINT *,'NZ_BUILD =', NZ_BUILD

  ! allocate arrays
  ALLOCATE(t(1:2,1:32,jjts:jjte))
  ALLOCATE(qci(1:2,1:32,2,jjts:jjte))
  ALLOCATE(qrs(1:2,1:32,3,jjts:jjte))
  ALLOCATE(q(1:2,1:33,jjms:jjme))
  ALLOCATE(den(1:2,1:33,jjms:jjme))
  ALLOCATE(p(1:2,1:33,jjms:jjme))
  ALLOCATE(delz(1:2,1:33,jjms:jjme))
  ALLOCATE(rain(1:2,jjms:jjme))
  ALLOCATE(rainncv(1:2,jjms:jjme))
  ALLOCATE(sr(1:2,jjms:jjme))
  ALLOCATE(snow(1:2,jjms:jjme))
  ALLOCATE(snowncv(1:2,jjms:jjme))
  ALLOCATE(graupel(1:2,jjms:jjme))
  ALLOCATE(graupelncv(1:2,jjms:jjme))

!$OMP PARALLEL DO &
!$OMP PRIVATE ( j ) &
!$OMP SCHEDULE(runtime)
  do j = jjts,jjte
    CALL firstTouch(t(iits,kts,j), q(iims,kms,j)              &
               ,qci(iits,kts,1,j), qrs(iits,kts,1,j)          &
               ,den(iims,kms,j)                               &
               ,p(iims,kms,j), delz(iims,kms,j)               &
               ,j                                             &
               ,rain(iims,j),rainncv(iims,j)                  &
               ,sr(iims,j)                                    &
               ,iids,iide, jjds,jjde, kds,kde                 &
               ,iims,iime, jjms,jjme, kms,kme                 &
               ,iits,iite, jjts,jjte, kts,kte                 &
               ,snow,snowncv                                  &
               ,graupel,graupelncv                            &
                                                              )
  enddo  ! j loop
!$OMP END PARALLEL DO

  ! read remaining input data
  call readarray3(t,'t',unitno,its,ite)
  call readarray4(qci,'qci',unitno,its,ite)
  call readarray4(qrs,'qrs',unitno,its,ite)
  call readarray3(q,'q',unitno,its,ite)
  call readarray3(den,'den',unitno,its,ite)
  call readarray3(p,'p',unitno,its,ite)
  call readarray3(delz,'delz',unitno,its,ite)
  read(unitno) delt
  print *,' delt = ',delt
  read(unitno) g
  print *,' g = ',g
  read(unitno) cpd
  print *,' cpd = ',cpd
  read(unitno) cpv
  print *,' cpv = ',cpv
  read(unitno) t0c
  print *,' t0c = ',t0c
  read(unitno) den0
  print *,' den0 = ',den0
  read(unitno) rd
  print *,' rd = ',rd
  read(unitno) rv
  print *,' rv = ',rv
  read(unitno) ep1
  print *,' ep1 = ',ep1
  read(unitno) ep2
  print *,' ep2 = ',ep2
  read(unitno) qmin
  print *,' qmin = ',qmin
  read(unitno) XLS
  print *,' XLS = ',XLS
  read(unitno) XLV0
  print *,' XLV0 = ',XLV0
  read(unitno) XLF0
  print *,' XLF0 = ',XLF0
  read(unitno) cliq
  print *,' cliq = ',cliq
  read(unitno) cice
  print *,' cice = ',cice
  read(unitno) psat
  print *,' psat = ',psat
  read(unitno) denr
  print *,' denr = ',denr
  call readarray2(rain,'rain',unitno,its,ite)
  call readarray2(rainncv,'rainncv',unitno,its,ite)
  call readarray2(sr,'sr',unitno,its,ite)
  call readarray2(snow,'snow',unitno,its,ite)
  call readarray2(snowncv,'snowncv',unitno,its,ite)
  call readarray2(graupel,'graupel',unitno,its,ite)
  call readarray2(graupelncv,'graupelncv',unitno,its,ite)
  close(unitno)

  ! minimize timer overhead inside OpenMP loop
  ret = gptlinit_handle ('WSM62D', handle)
  ! call WSM6
  ret = gptlstart('WSM62D+OpenMP')
!$OMP PARALLEL DO &
!$OMP PRIVATE ( j,ret ) &
!$OMP SCHEDULE(runtime)
  do j = jjts,jjte
    ret = gptlstart_handle ('WSM62D', handle)
    CALL wsm62D(t(iits,kts,j), q(iims,kms,j)                  &
               ,qci(iits,kts,1,j), qrs(iits,kts,1,j)          &
               ,den(iims,kms,j)                               &
               ,p(iims,kms,j), delz(iims,kms,j)               &
               ,delt,g, cpd, cpv, rd, rv, t0c                 &
               ,ep1, ep2, qmin                                &
               ,XLS, XLV0, XLF0, den0, denr                   &
               ,cliq,cice,psat                                &
               ,j                                             &
               ,rain(iims,j),rainncv(iims,j)                  &
               ,sr(iims,j)                                    &
               ,iids,iide, jjds,jjde, kds,kde                 &
               ,iims,iime, jjms,jjme, kms,kme                 &
               ,iits,iite, jjts,jjte, kts,kte                 &
               ,snow,snowncv                                  &
               ,graupel,graupelncv                            &
                                                              )
    ret = gptlstop_handle ('WSM62D', handle)
  enddo  ! j loop
!$OMP END PARALLEL DO
   ret = gptlstop('WSM62D+OpenMP')

  ! write output data
  PRINT *,'wsm62D():  itimestep == ',itimestep,', write output state'
  fn = 'wsm6_output.dat'
  unitno=31
  open (unitno,file=trim(fn),form="unformatted",action='write', &
        iostat=ios)
  if (ios /= 0) then
    write(6,*) 'ERROR: failed to open output file ',trim(fn), &
               ' . stopping'
    stop
  endif
  call writearray3(t,'t',unitno,its,ite)
  call writearray4(qci,'qci',unitno,its,ite)
  call writearray4(qrs,'qrs',unitno,its,ite)
  call writearray3(q,'q',unitno,its,ite)
  call writearray2(rain,'rain',unitno,its,ite)
  call writearray2(rainncv,'rainncv',unitno,its,ite)
  call writearray2(sr,'sr',unitno,its,ite)
  call writearray2(snow,'snow',unitno,its,ite)
  call writearray2(snowncv,'snowncv',unitno,its,ite)
  call writearray2(graupel,'graupel',unitno,its,ite)
  call writearray2(graupelncv,'graupelncv',unitno,its,ite)
  close(unitno)

  ! deallocate arrays
  DEALLOCATE(t)
  DEALLOCATE(qci)
  DEALLOCATE(qrs)
  DEALLOCATE(q)
  DEALLOCATE(den)
  DEALLOCATE(p)
  DEALLOCATE(delz)
  DEALLOCATE(rain)
  DEALLOCATE(rainncv)
  DEALLOCATE(sr)
  DEALLOCATE(snow)
  DEALLOCATE(snowncv)
  DEALLOCATE(graupel)
  DEALLOCATE(graupelncv)

  ret = gptlstop('Total')
  ret = gptlget_wallclock ('Total', 0, totaltime)  ! The "0" is thread number
  print*,''
  print*,'Total time =' , totaltime

!+---+-----------------------------------------------------------------+

  ! print timing info
  ret = gptlpr (0)
  ret = gptlpr_summary (0)

  END PROGRAM wsm6

