MODULE ctrl_output
   !===========================================================================================
   ! generic output functions for SUEWS
   ! authors: Ting Sun (ting.sun@reading.ac.uk)
   !
   ! disclamier:
   !     This code employs the netCDF Fortran 90 API.
   !     Full documentation of the netCDF Fortran 90 API can be found at:
   !     https://www.unidata.ucar.edu/software/netcdf/netcdf-4/newdocs/netcdf-f90/
   !     Part of the work is under the help of examples provided by the documentation.
   !
   ! purpose:
   ! these subroutines write out the results of SUEWS in netCDF format.
   !
   !
   ! history:
   ! TS 20161209: initial version of netcdf function
   ! TS 20161213: standalise the txt2nc procedure
   ! TS 20170414: generic output procedures
   ! TS 20171016: added support for DailyState
   ! TS 20171017: combined txt and nc wrappers into one: reduced duplicate code at two places
   !===========================================================================================

   USE allocateArray
   USE cbl_module
   USE data_in
   ! USE defaultNotUsed
   ! USE ESTM_data
   USE gis_data
   ! USE initial
   USE sues_data
   USE time
   USE strings

   IMPLICIT NONE

   INTEGER :: n

   CHARACTER(len=10), PARAMETER:: & !Define useful formats here
      fy = 'i0004,1X', & !4 digit integer for year
      ft = 'i0004,1X', & !3 digit integer for id, it, imin
      fd = 'f08.4,1X', & !3 digits + 4 dp for dectime
      f94 = 'f09.4,1X', & !standard output format: 4 dp + 4 digits
      f104 = 'f10.4,1X', & !standard output format: 4 dp + 5 digits
      f106 = 'f10.6,1X', & !standard output format: 6 dp + 3 digits
      f146 = 'f14.6,1X'   !standard output format: 6 dp + 7 digits

   CHARACTER(len=1), PARAMETER:: & ! Define aggregation methods here
      aT = 'T', &   !time columns
      aA = 'A', &   !average
      aS = 'S', &   !sum
      aL = 'L'     !last value

   CHARACTER(len=3):: itext

   ! define type: variable attributes
   TYPE varAttr
      CHARACTER(len=20) :: header ! short name in headers
      CHARACTER(len=12) :: unit   ! unit
      CHARACTER(len=10) :: fmt    ! output format
      CHARACTER(len=100) :: longNm ! long name for detailed description
      CHARACTER(len=1)  :: aggreg ! aggregation method
      CHARACTER(len=10) :: group  ! group: datetime, default, ESTM, Snow, etc.
      INTEGER             :: level  ! output priority level: 0 for highest (defualt output)
   END TYPE varAttr

   ! initialise valist
   TYPE(varAttr) :: varListAll(600)

   ! datetime:
   DATA(varListAll(n), n=1, 5)/ &
      varAttr('Year', 'YYYY', fy, 'Year', aT, 'datetime', 0), &
      varAttr('DOY', 'DOY', ft, 'Day of Year', aT, 'datetime', 0), &
      varAttr('Hour', 'HH', ft, 'Hour', aT, 'datetime', 0), &
      varAttr('Min', 'MM', ft, 'Minute', aT, 'datetime', 0), &
      varAttr('Dectime', '-', fd, 'Decimal time', aT, 'datetime', 0) &
      /

   ! defualt:
   DATA(varListAll(n), &
        n=5 + 1, &
        ncolumnsDataOutSUEWS)/ &
      varAttr('Kdown', 'W m-2', f104, 'Incoming shortwave radiation', aA, 'SUEWS', 0), &
      varAttr('Kup', 'W m-2', f104, 'Outgoing shortwave radiation', aA, 'SUEWS', 0), &
      varAttr('Ldown', 'W m-2', f104, 'Incoming longwave radiation', aA, 'SUEWS', 0), &
      varAttr('Lup', 'W m-2', f104, 'Outgoing longwave radiation', aA, 'SUEWS', 0), &
      varAttr('Tsurf', 'degC', f104, 'Bulk surface temperature', aA, 'SUEWS', 0), &
      varAttr('QN', 'W m-2', f104, 'Net all-wave radiation', aA, 'SUEWS', 0), &
      varAttr('QF', 'W m-2', f104, 'Anthropogenic heat flux', aA, 'SUEWS', 0), &
      varAttr('QS', 'W m-2', f104, 'Net storage heat flux', aA, 'SUEWS', 0), &
      varAttr('QH', 'W m-2', f104, 'Sensible heat flux', aA, 'SUEWS', 0), &
      varAttr('QE', 'W m-2', f104, 'Latent heat flux', aA, 'SUEWS', 0), &
      varAttr('QHlumps', 'W m-2', f104, 'Sensible heat flux (using LUMPS)', aA, 'SUEWS', 1), &
      varAttr('QElumps', 'W m-2', f104, 'Latent heat flux (using LUMPS)', aA, 'SUEWS', 1), &
      varAttr('QHresis', 'W m-2', f104, 'Sensible heat flux (resistance method)', aA, 'SUEWS', 1), &
      varAttr('Rain', 'mm', f104, 'Rain', aS, 'SUEWS', 0), &
      varAttr('Irr', 'mm', f104, 'Irrigation', aS, 'SUEWS', 0), &
      varAttr('Evap', 'mm', f104, 'Evaporation', aS, 'SUEWS', 0), &
      varAttr('RO', 'mm', f104, 'Runoff', aS, 'SUEWS', 0), &
      varAttr('TotCh', 'mm', f146, 'Surface and soil moisture change', aS, 'SUEWS', 0), &
      varAttr('SurfCh', 'mm', f146, 'Surface moisture change', aS, 'SUEWS', 0), &
      varAttr('State', 'mm', f104, 'Surface Wetness State', aL, 'SUEWS', 0), &
      varAttr('NWtrState', 'mm', f104, 'Surface wetness state (non-water surfaces)', aL, 'SUEWS', 0), &
      varAttr('Drainage', 'mm', f104, 'Drainage', aS, 'SUEWS', 0), &
      varAttr('SMD', 'mm', f94, 'Soil Moisture Deficit', aL, 'SUEWS', 0), &
      varAttr('FlowCh', 'mm', f104, 'Additional flow into water body', aS, 'SUEWS', 1), &
      varAttr('AddWater', 'mm', f104, 'Addtional water from other grids', aS, 'SUEWS', 1), &
      varAttr('ROSoil', 'mm', f104, 'Runoff to soil', aS, 'SUEWS', 1), &
      varAttr('ROPipe', 'mm', f104, 'Runoff to pipes', aS, 'SUEWS', 1), &
      varAttr('ROImp', 'mm', f104, 'Runoff over impervious surfaces', aS, 'SUEWS', 1), &
      varAttr('ROVeg', 'mm', f104, 'Runoff over vegetated surfaces', aS, 'SUEWS', 1), &
      varAttr('ROWater', 'mm', f104, 'Runoff for water surface', aS, 'SUEWS', 1), &
      varAttr('WUInt', 'mm', f94, 'InternalWaterUse', aS, 'SUEWS', 1), &
      varAttr('WUEveTr', 'mm', f94, 'Water use for evergreen trees', aS, 'SUEWS', 1), &
      varAttr('WUDecTr', 'mm', f94, 'Water use for deciduous trees', aS, 'SUEWS', 1), &
      varAttr('WUGrass', 'mm', f94, 'Water use for grass', aS, 'SUEWS', 1), &
      varAttr('SMDPaved', 'mm', f94, 'Soil moisture deficit for paved surface', aL, 'SUEWS', 1), &
      varAttr('SMDBldgs', 'mm', f94, 'Soil moisture deficit for building surface', aL, 'SUEWS', 1), &
      varAttr('SMDEveTr', 'mm', f94, 'Soil moisture deficit for evergreen tree surface', aL, 'SUEWS', 1), &
      varAttr('SMDDecTr', 'mm', f94, 'Soil moisture deficit for deciduous tree surface', aL, 'SUEWS', 1), &
      varAttr('SMDGrass', 'mm', f94, 'Soil moisture deficit for grass surface', aL, 'SUEWS', 1), &
      varAttr('SMDBSoil', 'mm', f94, 'Soil moisture deficit for bare soil surface', aL, 'SUEWS', 1), &
      varAttr('StPaved', 'mm', f94, 'Surface wetness state for paved surface', aL, 'SUEWS', 1), &
      varAttr('StBldgs', 'mm', f94, 'Surface wetness state for building surface', aL, 'SUEWS', 1), &
      varAttr('StEveTr', 'mm', f94, 'Surface wetness state for evergreen tree surface', aL, 'SUEWS', 1), &
      varAttr('StDecTr', 'mm', f94, 'Surface wetness state for deciduous tree surface', aL, 'SUEWS', 1), &
      varAttr('StGrass', 'mm', f94, 'Surface wetness state for grass surface', aL, 'SUEWS', 1), &
      varAttr('StBSoil', 'mm', f94, 'Surface wetness state for bare soil surface', aL, 'SUEWS', 1), &
      varAttr('StWater', 'mm', f104, 'Surface wetness state for water surface', aL, 'SUEWS', 1), &
      varAttr('Zenith', 'degree', f104, 'Solar zenith angle', aL, 'SUEWS', 0), &
      varAttr('Azimuth', 'degree', f94, 'Solar azimuth angle', aL, 'SUEWS', 0), &
      varAttr('AlbBulk', '1', f94, 'Bulk albedo', aA, 'SUEWS', 0), &
      varAttr('Fcld', '1', f94, 'Cloud fraction', aA, 'SUEWS', 0), &
      varAttr('LAI', 'm2 m-2', f94, 'Leaf area index', aA, 'SUEWS', 0), &
      varAttr('z0m', 'm', f94, 'Roughness length for momentum', aA, 'SUEWS', 1), &
      varAttr('zdm', 'm', f94, 'Zero-plane displacement height', aA, 'SUEWS', 1), &
      varAttr('UStar', 'm s-1', f94, 'Friction velocity', aA, 'SUEWS', 0), &
      varAttr('Lob', 'm', f146, 'Obukhov length', aA, 'SUEWS', 0), &
      varAttr('RA', 's m-1', f104, 'Aerodynamic resistance', aA, 'SUEWS', 1), &
      varAttr('RS', 's m-1', f104, 'Surface resistance', aA, 'SUEWS', 1), &
      varAttr('Fc', 'umol m-2 s-1', f94, 'CO2 flux', aA, 'SUEWS', 0), &
      varAttr('FcPhoto', 'umol m-2 s-1', f94, 'CO2 flux from photosynthesis', aA, 'SUEWS', 1), &
      varAttr('FcRespi', 'umol m-2 s-1', f94, 'CO2 flux from respiration', aA, 'SUEWS', 1), &
      varAttr('FcMetab', 'umol m-2 s-1', f94, 'CO2 flux from metabolism', aA, 'SUEWS', 1), &
      varAttr('FcTraff', 'umol m-2 s-1', f94, 'CO2 flux from traffic', aA, 'SUEWS', 1), &
      varAttr('FcBuild', 'umol m-2 s-1', f94, 'CO2 flux from buildings', aA, 'SUEWS', 1), &
      varAttr('FcPoint', 'umol m-2 s-1', f94, 'CO2 flux from point source', aA, 'SUEWS', 1), &
      varAttr('QNSnowFr', 'W m-2', f94, 'Net all-wave radiation for non-snow area', aA, 'SUEWS', 2), &
      varAttr('QNSnow', 'W m-2', f94, 'Net all-wave radiation for snow area', aA, 'SUEWS', 2), &
      varAttr('AlbSnow', '-', f94, 'Snow albedo', aA, 'SUEWS', 2), &
      varAttr('QM', 'W m-2', f106, 'Snow-related heat exchange', aA, 'SUEWS', 2), &
      varAttr('QMFreeze', 'W m-2', f146, 'Internal energy change', aA, 'SUEWS', 2), &
      varAttr('QMRain', 'W m-2', f106, 'Heat released by rain on snow', aA, 'SUEWS', 2), &
      varAttr('SWE', 'mm', f104, 'Snow water equivalent', aA, 'SUEWS', 2), &
      varAttr('MeltWater', 'mm', f104, 'Meltwater', aA, 'SUEWS', 2), &
      varAttr('MeltWStore', 'mm', f104, 'Meltwater store', aA, 'SUEWS', 2), &
      varAttr('SnowCh', 'mm', f104, 'Change in snow pack', aS, 'SUEWS', 2), &
      varAttr('SnowRPaved', 'mm', f94, 'Snow removed from paved surface', aS, 'SUEWS', 2), &
      varAttr('SnowRBldgs', 'mm', f94, 'Snow removed from building surface', aS, 'SUEWS', 2), &
      varAttr('Ts', 'degC', f94, 'Skin temperature', aA, 'SUEWS', 0), &
      varAttr('T2', 'degC', f94, 'Air temperature at 2 m', aA, 'SUEWS', 0), &
      varAttr('Q2', 'g kg-1', f94, 'Specific humidity at 2 m', aA, 'SUEWS', 0), &
      varAttr('U10', 'm s-1', f94, 'Wind speed at 10 m', aA, 'SUEWS', 0), &
      varAttr('RH2', '%', f94, 'Relative humidity at 2 m', aA, 'SUEWS', 0) &
      /

   ! BEERS (successor of SOLWEIG):
   DATA(varListAll(n), &
        n=ncolumnsDataOutSUEWS + 1, &
        ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5)/ &
      varAttr('azimuth', 'to_add', f106, 'azimuth', aA, 'BEERS', 0), &
      varAttr('altitude', 'to_add', f106, 'altitude', aA, 'BEERS', 0), &
      varAttr('GlobalRad', 'W m-2', f106, 'Global Irradiance', aA, 'BEERS', 0), &
      varAttr('DiffuseRad', 'W m-2', f106, 'Diffuse Radiation', aA, 'BEERS', 0), &
      varAttr('DirectRad', 'W m-2', f106, 'Direct Radiation', aA, 'BEERS', 0), &
      varAttr('Kdown2d', 'W m-2', f106, 'Incoming shortwave radiation at POI', aA, 'BEERS', 0), &
      varAttr('Kup2d', 'W m-2', f106, 'Outgoing shortwave radiation at POI', aA, 'BEERS', 0), &
      varAttr('Ksouth', 'W m-2', f106, 'Shortwave radiation from south at POI', aA, 'BEERS', 0), &
      varAttr('Kwest', 'W m-2', f106, 'Shortwave radiation from west at POI', aA, 'BEERS', 0), &
      varAttr('Knorth', 'W m-2', f106, 'Shortwave radiation from north at POI', aA, 'BEERS', 0), &
      varAttr('Keast', 'W m-2', f106, 'Shortwave radiation from east at POI', aA, 'BEERS', 0), &
      varAttr('Ldown2d', 'W m-2', f106, 'Incoming longwave radiation at POI', aA, 'BEERS', 0), &
      varAttr('Lup2d', 'W m-2', f106, 'Outgoing longwave radiation at POI', aA, 'BEERS', 0), &
      varAttr('Lsouth', 'W m-2', f106, 'Longwave radiation from west at POI', aA, 'BEERS', 0), &
      varAttr('Lwest', 'W m-2', f106, 'Longwave radiation from south at POI', aA, 'BEERS', 0), &
      varAttr('Lnorth', 'W m-2', f106, 'Longwave radiation from north at POI', aA, 'BEERS', 0), &
      varAttr('Least', 'W m-2', f106, 'Longwave radiation from east at POI', aA, 'BEERS', 0), &
      varAttr('Tmrt', 'degC', f106, 'Mean Radiant Temperature', aA, 'BEERS', 0), &
      varAttr('I0', 'W m-2', f106, 'theoretical value of maximum incoming solar radiation', aA, 'BEERS', 0), &
      varAttr('CI', '', f106, 'clearness index for Ldown', aA, 'BEERS', 0), &
      ! varAttr('gvf', '', f106, 'Ground view factor', aA, 'BEERS', 0), &
      varAttr('SH_Ground', '', f106, 'shadowground', aA, 'BEERS', 0), &
      varAttr('SH_Walls', '', f106, 'shadowwalls', aA, 'BEERS', 0), &
      varAttr('SVF_Ground', '', f106, 'Sky View Factor from ground', aA, 'BEERS', 0), &
      varAttr('SVF_Roof', '', f106, 'Sky View Factor from roof', aA, 'BEERS', 0), &
      varAttr('SVF_BdVeg', '', f106, 'Sky View Factor from buildings and vegetation', aA, 'BEERS', 0), &
      varAttr('Emis_Sky', 'degC', f106, 'clear-sky emissivity from Prata (1996)', aA, 'BEERS', 0), &
      varAttr('Ta', 'degC', f104, 'Air temperature', aA, 'BEERS', 0), &
      varAttr('Tg', 'degC', f104, 'Ground Surface temperature', aA, 'BEERS', 0), &
      varAttr('Tw', 'degC', f104, 'Wall Surface temperature', aA, 'BEERS', 0) &
      /

   ! BL:
   DATA(varListAll(n), &
        n=ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 + 1, &
        ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 + ncolumnsdataOutBL - 5)/ &
      varAttr('z', 'to_add', f104, 'z', aA, 'BL', 0), &
      varAttr('theta', 'to_add', f104, 'theta', aA, 'BL', 0), &
      varAttr('q', 'to_add', f104, 'q', aA, 'BL', 0), &
      varAttr('theta+', 'to_add', f104, 'theta+', aA, 'BL', 0), &
      varAttr('q+', 'to_add', f104, 'q+', aA, 'BL', 0), &
      varAttr('Temp_C', 'to_add', f104, 'Temp_C', aA, 'BL', 0), &
      varAttr('rh', 'to_add', f104, 'rh', aA, 'BL', 0), &
      varAttr('QH_use', 'to_add', f104, 'QH_use', aA, 'BL', 0), &
      varAttr('QE_use', 'to_add', f104, 'QE_use', aA, 'BL', 0), &
      varAttr('Press_hPa', 'to_add', f104, 'Press_hPa', aA, 'BL', 0), &
      varAttr('avu1', 'to_add', f104, 'avu1', aA, 'BL', 0), &
      varAttr('UStar', 'to_add', f104, 'UStar', aA, 'BL', 0), &
      varAttr('avdens', 'to_add', f104, 'avdens', aA, 'BL', 0), &
      varAttr('lv_J_kg', 'to_add', f146, 'lv_J_kg', aA, 'BL', 0), &
      varAttr('avcp', 'to_add', f104, 'avcp', aA, 'BL', 0), &
      varAttr('gamt', 'to_add', f104, 'gamt', aA, 'BL', 0), &
      varAttr('gamq', 'to_add', f104, 'gamq', aA, 'BL', 0) &
      /

   ! Snow:
   DATA(varListAll(n), &
        n=ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 + ncolumnsdataOutBL - 5 + 1, &
        ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 + ncolumnsdataOutBL - 5 + ncolumnsDataOutSnow - 5)/ &
      varAttr('SWE_Paved', 'mm', f106, 'Snow water equivalent for paved surface', aA, 'snow', 0), &
      varAttr('SWE_Bldgs', 'mm', f106, 'Snow water equivalent for building surface', aA, 'snow', 0), &
      varAttr('SWE_EveTr', 'mm', f106, 'Snow water equivalent for evergreen tree surface', aA, 'snow', 0), &
      varAttr('SWE_DecTr', 'mm', f106, 'Snow water equivalent for deciduous tree surface', aA, 'snow', 0), &
      varAttr('SWE_Grass', 'mm', f106, 'Snow water equivalent for grass surface', aA, 'snow', 0), &
      varAttr('SWE_BSoil', 'mm', f106, 'Snow water equivalent for bare soil surface', aA, 'snow', 0), &
      varAttr('SWE_Water', 'mm', f106, 'Snow water equivalent for water surface', aA, 'snow', 0), &
      varAttr('Mw_Paved', 'mm', f106, 'Meltwater for paved surface', aS, 'snow', 0), &
      varAttr('Mw_Bldgs', 'mm', f106, 'Meltwater for building surface', aS, 'snow', 0), &
      varAttr('Mw_EveTr', 'mm', f106, 'Meltwater for evergreen tree surface', aS, 'snow', 0), &
      varAttr('Mw_DecTr', 'mm', f106, 'Meltwater for deciduous tree surface', aS, 'snow', 0), &
      varAttr('Mw_Grass', 'mm', f106, 'Meltwater for grass surface', aS, 'snow', 0), &
      varAttr('Mw_BSoil', 'mm', f106, 'Meltwater for bare soil surface', aS, 'snow', 0), &
      varAttr('Mw_Water', 'mm', f106, 'Meltwater for water surface', aS, 'snow', 0), &
      varAttr('Qm_Paved', 'W m-2', f106, 'Snow-related heat exchange for paved surface', aA, 'snow', 0), &
      varAttr('Qm_Bldgs', 'W m-2', f106, 'Snow-related heat exchange for building surface', aA, 'snow', 0), &
      varAttr('Qm_EveTr', 'W m-2', f106, 'Snow-related heat exchange for evergreen tree surface', aA, 'snow', 0), &
      varAttr('Qm_DecTr', 'W m-2', f106, 'Snow-related heat exchange for deciduous tree surface', aA, 'snow', 0), &
      varAttr('Qm_Grass', 'W m-2', f106, 'Snow-related heat exchange for grass surface', aA, 'snow', 0), &
      varAttr('Qm_BSoil', 'W m-2', f106, 'Snow-related heat exchange for bare soil surface', aA, 'snow', 0), &
      varAttr('Qm_Water', 'W m-2', f106, 'Snow-related heat exchange for water surface', aA, 'snow', 0), &
      varAttr('Qa_Paved', 'W m-2', f106, 'Advective heat for paved surface', aA, 'snow', 0), &
      varAttr('Qa_Bldgs', 'W m-2', f106, 'Advective heat for building surface', aA, 'snow', 0), &
      varAttr('Qa_EveTr', 'W m-2', f106, 'Advective heat for evergreen tree surface', aA, 'snow', 0), &
      varAttr('Qa_DecTr', 'W m-2', f106, 'Advective heat for deciduous tree surface', aA, 'snow', 0), &
      varAttr('Qa_Grass', 'W m-2', f106, 'Advective heat for grass surface', aA, 'snow', 0), &
      varAttr('Qa_BSoil', 'W m-2', f106, 'Advective heat for bare soil surface', aA, 'snow', 0), &
      varAttr('Qa_Water', 'W m-2', f106, 'Advective heat for water surface', aA, 'snow', 0), &
      varAttr('QmFr_Paved', 'W m-2', f146, 'Heat related to freezing for paved surface', aA, 'snow', 0), &
      varAttr('QmFr_Bldgs', 'W m-2', f146, 'Heat related to freezing for building surface', aA, 'snow', 0), &
      varAttr('QmFr_EveTr', 'W m-2', f146, 'Heat related to freezing for evergreen tree surface', aA, 'snow', 0), &
      varAttr('QmFr_DecTr', 'W m-2', f146, 'Heat related to freezing for deciduous tree surface', aA, 'snow', 0), &
      varAttr('QmFr_Grass', 'W m-2', f146, 'Heat related to freezing for grass surface', aA, 'snow', 0), &
      varAttr('QmFr_BSoil', 'W m-2', f146, 'Heat related to freezing for bare soil surface', aA, 'snow', 0), &
      varAttr('QmFr_Water', 'W m-2', f146, 'Heat related to freezing for water surface', aA, 'snow', 0), &
      varAttr('fr_Paved', '1', f106, 'Fraction of snow for paved surface', aA, 'snow', 0), &
      varAttr('fr_Bldgs', '1', f106, 'Fraction of snow for building surface', aA, 'snow', 0), &
      varAttr('fr_EveTr', '1', f106, 'Fraction of snow for evergreen tree surface', aA, 'snow', 0), &
      varAttr('fr_DecTr', '1', f106, 'Fraction of snow for deciduous tree surface', aA, 'snow', 0), &
      varAttr('fr_Grass', '1', f106, 'Fraction of snow for grass surface', aA, 'snow', 0), &
      varAttr('fr_BSoil', '1', f106, 'Fraction of snow for bare soil surface', aA, 'snow', 0), &
      varAttr('RainSn_Paved', 'mm', f146, 'Rain on snow for paved surface', aS, 'snow', 0), &
      varAttr('RainSn_Bldgs', 'mm', f146, 'Rain on snow for building surface', aS, 'snow', 0), &
      varAttr('RainSn_EveTr', 'mm', f146, 'Rain on snow for evergreen tree surface', aS, 'snow', 0), &
      varAttr('RainSn_DecTr', 'mm', f146, 'Rain on snow for deciduous tree surface', aS, 'snow', 0), &
      varAttr('RainSn_Grass', 'mm', f146, 'Rain on snow for grass surface', aS, 'snow', 0), &
      varAttr('RainSn_BSoil', 'mm', f146, 'Rain on snow for bare soil surface', aS, 'snow', 0), &
      varAttr('RainSn_Water', 'mm', f146, 'Rain on snow for water surface', aS, 'snow', 0), &
      varAttr('Qn_PavedSnow', 'W m-2', f146, 'Net all-wave radiation for snow paved surface', aA, 'snow', 0), &
      varAttr('Qn_BldgsSnow', 'W m-2', f146, 'Net all-wave radiation for snow building surface', aA, 'snow', 0), &
      varAttr('Qn_EveTrSnow', 'W m-2', f146, 'Net all-wave radiation for snow evergreen tree surface', aA, 'snow', 0), &
      varAttr('Qn_DecTrSnow', 'W m-2', f146, 'Net all-wave radiation for snow deciduous tree surface', aA, 'snow', 0), &
      varAttr('Qn_GrassSnow', 'W m-2', f146, 'Net all-wave radiation for snow grass surface', aA, 'snow', 0), &
      varAttr('Qn_BSoilSnow', 'W m-2', f146, 'Net all-wave radiation for snow bare soil surface', aA, 'snow', 0), &
      varAttr('Qn_WaterSnow', 'W m-2', f146, 'Net all-wave radiation for snow water surface', aA, 'snow', 0), &
      varAttr('kup_PavedSnow', 'W m-2', f146, 'Reflected shortwave radiation for snow paved surface', aA, 'snow', 0), &
      varAttr('kup_BldgsSnow', 'W m-2', f146, 'Reflected shortwave radiation for snow building surface', aA, 'snow', 0), &
      varAttr('kup_EveTrSnow', 'W m-2', f146, 'Reflected shortwave radiation for snow evergreen tree surface', aA, 'snow', 0), &
      varAttr('kup_DecTrSnow', 'W m-2', f146, 'Reflected shortwave radiation for snow deciduous tree surface', aA, 'snow', 0), &
      varAttr('kup_GrassSnow', 'W m-2', f146, 'Reflected shortwave radiation for snow grass surface', aA, 'snow', 0), &
      varAttr('kup_BSoilSnow', 'W m-2', f146, 'Reflected shortwave radiation for snow bare soil surface', aA, 'snow', 0), &
      varAttr('kup_WaterSnow', 'W m-2', f146, 'Reflected shortwave radiation for snow water surface', aA, 'snow', 0), &
      varAttr('frMelt_Paved', 'mm', f146, 'Amount of freezing melt water for paved surface', aA, 'snow', 0), &
      varAttr('frMelt_Bldgs', 'mm', f146, 'Amount of freezing melt water for building surface', aA, 'snow', 0), &
      varAttr('frMelt_EveTr', 'mm', f146, 'Amount of freezing melt water for evergreen tree surface', aA, 'snow', 0), &
      varAttr('frMelt_DecTr', 'mm', f146, 'Amount of freezing melt water for deciduous tree surface', aA, 'snow', 0), &
      varAttr('frMelt_Grass', 'mm', f146, 'Amount of freezing melt water for grass surface', aA, 'snow', 0), &
      varAttr('frMelt_BSoil', 'mm', f146, 'Amount of freezing melt water for bare soil surface', aA, 'snow', 0), &
      varAttr('frMelt_Water', 'mm', f146, 'Amount of freezing melt water for water surface', aA, 'snow', 0), &
      varAttr('MwStore_Paved', 'mm', f146, 'Meltwater store for paved surface', aA, 'snow', 0), &
      varAttr('MwStore_Bldgs', 'mm', f146, 'Meltwater store for building surface', aA, 'snow', 0), &
      varAttr('MwStore_EveTr', 'mm', f146, 'Meltwater store for evergreen tree surface', aA, 'snow', 0), &
      varAttr('MwStore_DecTr', 'mm', f146, 'Meltwater store for deciduous tree surface', aA, 'snow', 0), &
      varAttr('MwStore_Grass', 'mm', f146, 'Meltwater store for grass surface', aA, 'snow', 0), &
      varAttr('MwStore_BSoil', 'mm', f146, 'Meltwater store for bare soil surface', aA, 'snow', 0), &
      varAttr('MwStore_Water', 'mm', f146, 'Meltwater store for water surface', aA, 'snow', 0), &
      varAttr('DensSnow_Paved', 'kg m-3', f146, 'Snow density for paved surface', aA, 'snow', 0), &
      varAttr('DensSnow_Bldgs', 'kg m-3', f146, 'Snow density for building surface', aA, 'snow', 0), &
      varAttr('DensSnow_EveTr', 'kg m-3', f146, 'Snow density for evergreen tree surface', aA, 'snow', 0), &
      varAttr('DensSnow_DecTr', 'kg m-3', f146, 'Snow density for deciduous tree surface', aA, 'snow', 0), &
      varAttr('DensSnow_Grass', 'kg m-3', f146, 'Snow density for grass surface', aA, 'snow', 0), &
      varAttr('DensSnow_BSoil', 'kg m-3', f146, 'Snow density for bare soil surface', aA, 'snow', 0), &
      varAttr('DensSnow_Water', 'kg m-3', f146, 'Snow density for water surface', aA, 'snow', 0), &
      varAttr('Sd_Paved', 'mm', f106, 'Snow depth for paved surface', aA, 'snow', 0), &
      varAttr('Sd_Bldgs', 'mm', f106, 'Snow depth for building surface', aA, 'snow', 0), &
      varAttr('Sd_EveTr', 'mm', f106, 'Snow depth for evergreen tree surface', aA, 'snow', 0), &
      varAttr('Sd_DecTr', 'mm', f106, 'Snow depth for deciduous tree surface', aA, 'snow', 0), &
      varAttr('Sd_Grass', 'mm', f106, 'Snow depth for grass surface', aA, 'snow', 0), &
      varAttr('Sd_BSoil', 'mm', f106, 'Snow depth for bare soil surface', aA, 'snow', 0), &
      varAttr('Sd_Water', 'mm', f106, 'Snow depth for water surface', aA, 'snow', 0), &
      varAttr('Tsnow_Paved', 'degC', f146, 'Snow surface temperature for paved surface', aA, 'snow', 0), &
      varAttr('Tsnow_Bldgs', 'degC', f146, 'Snow surface temperature for building surface', aA, 'snow', 0), &
      varAttr('Tsnow_EveTr', 'degC', f146, 'Snow surface temperature for evergreen tree surface', aA, 'snow', 0), &
      varAttr('Tsnow_DecTr', 'degC', f146, 'Snow surface temperature for deciduous tree surface', aA, 'snow', 0), &
      varAttr('Tsnow_Grass', 'degC', f146, 'Snow surface temperature for grass surface', aA, 'snow', 0), &
      varAttr('Tsnow_BSoil', 'degC', f146, 'Snow surface temperature for bare soil surface', aA, 'snow', 0), &
      varAttr('Tsnow_Water', 'degC', f146, 'Snow surface temperature for water surface', aA, 'snow', 0), &
      varAttr('SnowAlb', '-', f146, 'Surface albedo for snow/ice', aA, 'snow', 0) &
      /

   ! ESTM:
   DATA(varListAll(n), &
        n=ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 + ncolumnsdataOutBL - 5 + ncolumnsDataOutSnow - 5 + 1, &
       ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 + ncolumnsdataOutBL - 5 + ncolumnsDataOutSnow - 5 &
       + ncolumnsDataOutESTM - 5)/ &
      varAttr('QS', 'W m-2', f104, 'Total Storage', aA, 'ESTM', 0), &
      varAttr('QSAir', 'W m-2', f104, 'Storage air', aA, 'ESTM', 0), &
      varAttr('QSWall', 'W m-2', f104, 'Storage Wall', aA, 'ESTM', 0), &
      varAttr('QSRoof', 'W m-2', f104, 'Storage Roof', aA, 'ESTM', 0), &
      varAttr('QSGround', 'W m-2', f104, 'Storage Ground', aA, 'ESTM', 0), &
      varAttr('QSIBld', 'W m-2', f104, 'Storage Internal building', aA, 'ESTM', 0), &
      varAttr('TWALL1', 'degK', f104, 'Temperature in wall layer 1', aA, 'ESTM', 0), &
      varAttr('TWALL2', 'degK', f104, 'Temperature in wall layer 2', aA, 'ESTM', 0), &
      varAttr('TWALL3', 'degK', f104, 'Temperature in wall layer 3', aA, 'ESTM', 0), &
      varAttr('TWALL4', 'degK', f104, 'Temperature in wall layer 4', aA, 'ESTM', 0), &
      varAttr('TWALL5', 'degK', f104, 'Temperature in wall layer 5', aA, 'ESTM', 0), &
      varAttr('TROOF1', 'degK', f104, 'Temperature in roof layer 1', aA, 'ESTM', 0), &
      varAttr('TROOF2', 'degK', f104, 'Temperature in roof layer 2', aA, 'ESTM', 0), &
      varAttr('TROOF3', 'degK', f104, 'Temperature in roof layer 3', aA, 'ESTM', 0), &
      varAttr('TROOF4', 'degK', f104, 'Temperature in roof layer 4', aA, 'ESTM', 0), &
      varAttr('TROOF5', 'degK', f104, 'Temperature in roof layer 5', aA, 'ESTM', 0), &
      varAttr('TGROUND1', 'degK', f104, 'Temperature in ground layer 1', aA, 'ESTM', 0), &
      varAttr('TGROUND2', 'degK', f104, 'Temperature in ground layer 2', aA, 'ESTM', 0), &
      varAttr('TGROUND3', 'degK', f104, 'Temperature in ground layer 3', aA, 'ESTM', 0), &
      varAttr('TGROUND4', 'degK', f104, 'Temperature in ground layer 4', aA, 'ESTM', 0), &
      varAttr('TGROUND5', 'degK', f104, 'Temperature in ground layer 5', aA, 'ESTM', 0), &
      varAttr('TiBLD1', 'degK', f104, 'Temperature in internal building layer 1', aA, 'ESTM', 0), &
      varAttr('TiBLD2', 'degK', f104, 'Temperature in internal building layer 2', aA, 'ESTM', 0), &
      varAttr('TiBLD3', 'degK', f104, 'Temperature in internal building layer 3', aA, 'ESTM', 0), &
      varAttr('TiBLD4', 'degK', f104, 'Temperature in internal building layer 4', aA, 'ESTM', 0), &
      varAttr('TiBLD5', 'degK', f104, 'Temperature in internal building layer 5', aA, 'ESTM', 0), &
      varAttr('TaBLD', 'degK', f104, 'Indoor air temperature', aA, 'ESTM', 0) &
      &/

   ! DailyState:
   DATA(varListAll(n), &
        n=ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 &
        + ncolumnsdataOutBL - 5 + ncolumnsDataOutSnow - 5 + ncolumnsDataOutESTM - 5 + 1, &
        ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 &
        + ncolumnsdataOutBL - 5 + ncolumnsDataOutSnow - 5 + ncolumnsDataOutESTM - 5 &
        + ncolumnsDataOutDailyState - 5)/ &
      varAttr('HDD1_h', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('HDD2_c', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('HDD3_Tmean', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('HDD4_T5d', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('P_day', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('DaysSR', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('GDD_EveTr', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('GDD_DecTr', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('GDD_Grass', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('SDD_EveTr', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('SDD_DecTr', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('SDD_Grass', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('Tmin', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('Tmax', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('DLHrs', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('LAI_EveTr', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('LAI_DecTr', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('LAI_Grass', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('DecidCap', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('Porosity', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('AlbEveTr', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('AlbDecTr', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('AlbGrass', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('WU_EveTr1', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('WU_EveTr2', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('WU_EveTr3', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('WU_DecTr1', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('WU_DecTr2', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('WU_DecTr3', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('WU_Grass1', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('WU_Grass2', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('WU_Grass3', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('deltaLAI', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('LAIlumps', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('AlbSnow', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('DensSnow_Paved', 'to be added', f146, 'to be added', aL, 'DailyState', 0), &
      varAttr('DensSnow_Bldgs', 'to be added', f146, 'to be added', aL, 'DailyState', 0), &
      varAttr('DensSnow_EveTr', 'to be added', f146, 'to be added', aL, 'DailyState', 0), &
      varAttr('DensSnow_DecTr', 'to be added', f146, 'to be added', aL, 'DailyState', 0), &
      varAttr('DensSnow_Grass', 'to be added', f146, 'to be added', aL, 'DailyState', 0), &
      varAttr('DensSnow_BSoil', 'to be added', f146, 'to be added', aL, 'DailyState', 0), &
      varAttr('DensSnow_Water', 'to be added', f146, 'to be added', aL, 'DailyState', 0), &
      varAttr('a1', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('a2', 'to be added', f104, 'to be added', aL, 'DailyState', 0), &
      varAttr('a3', 'to be added', f104, 'to be added', aL, 'DailyState', 0) &
      /

   ! RSL profiles
   DATA(varListAll(n), &
        n=ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 &
        + ncolumnsdataOutBL - 5 + ncolumnsDataOutSnow - 5 + ncolumnsDataOutESTM - 5 &
        + ncolumnsDataOutDailyState - 5 &
        + 1, &
        ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 &
        + ncolumnsdataOutBL - 5 + ncolumnsDataOutSnow - 5 + ncolumnsDataOutESTM - 5 &
        + ncolumnsDataOutDailyState - 5 &
        + ncolumnsDataOutRSL - 5)/ &
      varAttr('z_1', 'm', f104, '0.1Zh', aA, 'RSL', 0), &
      varAttr('z_2', 'm', f104, '0.2Zh', aA, 'RSL', 0), &
      varAttr('z_3', 'm', f104, '0.3Zh', aA, 'RSL', 0), &
      varAttr('z_4', 'm', f104, '0.4Zh', aA, 'RSL', 0), &
      varAttr('z_5', 'm', f104, '0.5Zh', aA, 'RSL', 0), &
      varAttr('z_6', 'm', f104, '0.6Zh', aA, 'RSL', 0), &
      varAttr('z_7', 'm', f104, '0.7Zh', aA, 'RSL', 0), &
      varAttr('z_8', 'm', f104, '0.8Zh', aA, 'RSL', 0), &
      varAttr('z_9', 'm', f104, '0.9Zh', aA, 'RSL', 0), &
      varAttr('z_10', 'm', f104, 'Zh', aA, 'RSL', 0), &
      varAttr('z_11', 'm', f104, '1.1Zh', aA, 'RSL', 0), &
      varAttr('z_12', 'm', f104, '1.2Zh', aA, 'RSL', 0), &
      varAttr('z_13', 'm', f104, '1.3Zh', aA, 'RSL', 0), &
      varAttr('z_14', 'm', f146, '1.4Zh', aA, 'RSL', 0), &
      varAttr('z_15', 'm', f104, '1.5Zh', aA, 'RSL', 0), &
      varAttr('z_16', 'm', f104, '1.6Zh', aA, 'RSL', 0), &
      varAttr('z_17', 'm', f104, '1.7Zh', aA, 'RSL', 0), &
      varAttr('z_18', 'm', f104, '1.8Zh', aA, 'RSL', 0), &
      varAttr('z_19', 'm', f104, '1.9Zh', aA, 'RSL', 0), &
      varAttr('z_20', 'm', f104, '2.0Zh', aA, 'RSL', 0), &
      varAttr('z_21', 'm', f146, '2.1Zh', aA, 'RSL', 0), &
      varAttr('z_22', 'm', f104, '2.2Zh', aA, 'RSL', 0), &
      varAttr('z_23', 'm', f104, '2.3Zh', aA, 'RSL', 0), &
      varAttr('z_24', 'm', f104, '2.4Zh', aA, 'RSL', 0), &
      varAttr('z_25', 'm', f104, '2.5Zh', aA, 'RSL', 0), &
      varAttr('z_26', 'm', f104, '2.6Zh', aA, 'RSL', 0), &
      varAttr('z_27', 'm', f104, '2.7Zh', aA, 'RSL', 0), &
      varAttr('z_28', 'm', f104, '2.8Zh', aA, 'RSL', 0), &
      varAttr('z_29', 'm', f104, '2.9Zh', aA, 'RSL', 0), &
      varAttr('z_30', 'm', f104, '3.0Zh', aA, 'RSL', 0), &
      varAttr('U_1', 'm s-1', f104, 'U at 0.1Zh', aA, 'RSL', 0), &
      varAttr('U_2', 'm s-1', f104, 'U at 0.2Zh', aA, 'RSL', 0), &
      varAttr('U_3', 'm s-1', f104, 'U at 0.3Zh', aA, 'RSL', 0), &
      varAttr('U_4', 'm s-1', f104, 'U at 0.4Zh', aA, 'RSL', 0), &
      varAttr('U_5', 'm s-1', f104, 'U at 0.5Zh', aA, 'RSL', 0), &
      varAttr('U_6', 'm s-1', f104, 'U at 0.6Zh', aA, 'RSL', 0), &
      varAttr('U_7', 'm s-1', f104, 'U at 0.7Zh', aA, 'RSL', 0), &
      varAttr('U_8', 'm s-1', f104, 'U at 0.8Zh', aA, 'RSL', 0), &
      varAttr('U_9', 'm s-1', f104, 'U at 0.9Zh', aA, 'RSL', 0), &
      varAttr('U_10', 'm s-1', f104, 'U at Zh', aA, 'RSL', 0), &
      varAttr('U_11', 'm s-1', f104, 'U at 1.1Zh', aA, 'RSL', 0), &
      varAttr('U_12', 'm s-1', f104, 'U at 1.2Zh', aA, 'RSL', 0), &
      varAttr('U_13', 'm s-1', f104, 'U at 1.3Zh', aA, 'RSL', 0), &
      varAttr('U_14', 'm s-1', f146, 'U at 1.4Zh', aA, 'RSL', 0), &
      varAttr('U_15', 'm s-1', f104, 'U at 1.5Zh', aA, 'RSL', 0), &
      varAttr('U_16', 'm s-1', f104, 'U at 1.6Zh', aA, 'RSL', 0), &
      varAttr('U_17', 'm s-1', f104, 'U at 1.7Zh', aA, 'RSL', 0), &
      varAttr('U_18', 'm s-1', f104, 'U at 1.8Zh', aA, 'RSL', 0), &
      varAttr('U_19', 'm s-1', f104, 'U at 1.9Zh', aA, 'RSL', 0), &
      varAttr('U_20', 'm s-1', f104, 'U at 2.0Zh', aA, 'RSL', 0), &
      varAttr('U_21', 'm s-1', f146, 'U at 2.1Zh', aA, 'RSL', 0), &
      varAttr('U_22', 'm s-1', f104, 'U at 2.2Zh', aA, 'RSL', 0), &
      varAttr('U_23', 'm s-1', f104, 'U at 2.3Zh', aA, 'RSL', 0), &
      varAttr('U_24', 'm s-1', f104, 'U at 2.4Zh', aA, 'RSL', 0), &
      varAttr('U_25', 'm s-1', f104, 'U at 2.5Zh', aA, 'RSL', 0), &
      varAttr('U_26', 'm s-1', f104, 'U at 2.6Zh', aA, 'RSL', 0), &
      varAttr('U_27', 'm s-1', f104, 'U at 2.7Zh', aA, 'RSL', 0), &
      varAttr('U_28', 'm s-1', f104, 'U at 2.8Zh', aA, 'RSL', 0), &
      varAttr('U_29', 'm s-1', f104, 'U at 2.9Zh', aA, 'RSL', 0), &
      varAttr('U_30', 'm s-1', f104, 'U at 3.0Zh', aA, 'RSL', 0), &
      varAttr('T_1', 'degC', f104, 'T at 0.1Zh', aA, 'RSL', 0), &
      varAttr('T_2', 'degC', f104, 'T at 0.2Zh', aA, 'RSL', 0), &
      varAttr('T_3', 'degC', f104, 'T at 0.3Zh', aA, 'RSL', 0), &
      varAttr('T_4', 'degC', f104, 'T at 0.4Zh', aA, 'RSL', 0), &
      varAttr('T_5', 'degC', f104, 'T at 0.5Zh', aA, 'RSL', 0), &
      varAttr('T_6', 'degC', f104, 'T at 0.6Zh', aA, 'RSL', 0), &
      varAttr('T_7', 'degC', f104, 'T at 0.7Zh', aA, 'RSL', 0), &
      varAttr('T_8', 'degC', f104, 'T at 0.8Zh', aA, 'RSL', 0), &
      varAttr('T_9', 'degC', f104, 'T at 0.9Zh', aA, 'RSL', 0), &
      varAttr('T_10', 'degC', f104, 'T at Zh', aA, 'RSL', 0), &
      varAttr('T_11', 'degC', f104, 'T at 1.1Zh', aA, 'RSL', 0), &
      varAttr('T_12', 'degC', f104, 'T at 1.2Zh', aA, 'RSL', 0), &
      varAttr('T_13', 'degC', f104, 'T at 1.3Zh', aA, 'RSL', 0), &
      varAttr('T_14', 'degC', f146, 'T at 1.4Zh', aA, 'RSL', 0), &
      varAttr('T_15', 'degC', f104, 'T at 1.5Zh', aA, 'RSL', 0), &
      varAttr('T_16', 'degC', f104, 'T at 1.6Zh', aA, 'RSL', 0), &
      varAttr('T_17', 'degC', f104, 'T at 1.7Zh', aA, 'RSL', 0), &
      varAttr('T_18', 'degC', f104, 'T at 1.8Zh', aA, 'RSL', 0), &
      varAttr('T_19', 'degC', f104, 'T at 1.9Zh', aA, 'RSL', 0), &
      varAttr('T_20', 'degC', f104, 'T at 2.0Zh', aA, 'RSL', 0), &
      varAttr('T_21', 'degC', f146, 'T at 2.1Zh', aA, 'RSL', 0), &
      varAttr('T_22', 'degC', f104, 'T at 2.2Zh', aA, 'RSL', 0), &
      varAttr('T_23', 'degC', f104, 'T at 2.3Zh', aA, 'RSL', 0), &
      varAttr('T_24', 'degC', f104, 'T at 2.4Zh', aA, 'RSL', 0), &
      varAttr('T_25', 'degC', f104, 'T at 2.5Zh', aA, 'RSL', 0), &
      varAttr('T_26', 'degC', f104, 'T at 2.6Zh', aA, 'RSL', 0), &
      varAttr('T_27', 'degC', f104, 'T at 2.7Zh', aA, 'RSL', 0), &
      varAttr('T_28', 'degC', f104, 'T at 2.8Zh', aA, 'RSL', 0), &
      varAttr('T_29', 'degC', f104, 'T at 2.9Zh', aA, 'RSL', 0), &
      varAttr('T_30', 'degC', f104, 'T at 3.0Zh', aA, 'RSL', 0), &
      varAttr('q_1', 'g kg-1', f104, 'q at 0.1Zh', aA, 'RSL', 0), &
      varAttr('q_2', 'g kg-1', f104, 'q at 0.2Zh', aA, 'RSL', 0), &
      varAttr('q_3', 'g kg-1', f104, 'q at 0.3Zh', aA, 'RSL', 0), &
      varAttr('q_4', 'g kg-1', f104, 'q at 0.4Zh', aA, 'RSL', 0), &
      varAttr('q_5', 'g kg-1', f104, 'q at 0.5Zh', aA, 'RSL', 0), &
      varAttr('q_6', 'g kg-1', f104, 'q at 0.6Zh', aA, 'RSL', 0), &
      varAttr('q_7', 'g kg-1', f104, 'q at 0.7Zh', aA, 'RSL', 0), &
      varAttr('q_8', 'g kg-1', f104, 'q at 0.8Zh', aA, 'RSL', 0), &
      varAttr('q_9', 'g kg-1', f104, 'q at 0.9Zh', aA, 'RSL', 0), &
      varAttr('q_10', 'g kg-1', f104, 'q at Zh', aA, 'RSL', 0), &
      varAttr('q_11', 'g kg-1', f104, 'q at 1.1Zh', aA, 'RSL', 0), &
      varAttr('q_12', 'g kg-1', f104, 'q at 1.2Zh', aA, 'RSL', 0), &
      varAttr('q_13', 'g kg-1', f104, 'q at 1.3Zh', aA, 'RSL', 0), &
      varAttr('q_14', 'g kg-1', f146, 'q at 1.4Zh', aA, 'RSL', 0), &
      varAttr('q_15', 'g kg-1', f104, 'q at 1.5Zh', aA, 'RSL', 0), &
      varAttr('q_16', 'g kg-1', f104, 'q at 1.6Zh', aA, 'RSL', 0), &
      varAttr('q_17', 'g kg-1', f104, 'q at 1.7Zh', aA, 'RSL', 0), &
      varAttr('q_18', 'g kg-1', f104, 'q at 1.8Zh', aA, 'RSL', 0), &
      varAttr('q_19', 'g kg-1', f104, 'q at 1.9Zh', aA, 'RSL', 0), &
      varAttr('q_20', 'g kg-1', f104, 'q at 2.0Zh', aA, 'RSL', 0), &
      varAttr('q_21', 'g kg-1', f146, 'q at 2.1Zh', aA, 'RSL', 0), &
      varAttr('q_22', 'g kg-1', f104, 'q at 2.2Zh', aA, 'RSL', 0), &
      varAttr('q_23', 'g kg-1', f104, 'q at 2.3Zh', aA, 'RSL', 0), &
      varAttr('q_24', 'g kg-1', f104, 'q at 2.4Zh', aA, 'RSL', 0), &
      varAttr('q_25', 'g kg-1', f104, 'q at 2.5Zh', aA, 'RSL', 0), &
      varAttr('q_26', 'g kg-1', f104, 'q at 2.6Zh', aA, 'RSL', 0), &
      varAttr('q_27', 'g kg-1', f104, 'q at 2.7Zh', aA, 'RSL', 0), &
      varAttr('q_28', 'g kg-1', f104, 'q at 2.8Zh', aA, 'RSL', 0), &
      varAttr('q_29', 'g kg-1', f104, 'q at 2.9Zh', aA, 'RSL', 0), &
      varAttr('q_30', 'g kg-1', f104, 'q at 3.0Zh', aA, 'RSL', 0), &
      ! debug info
      ! varAttr('L_stab', 'm', f104, 'threshold of Obukhob length under stable conditions', aA, 'RSL', 0), &
      ! varAttr('L_unstab', 'm', f104, 'threshold of Obukhob length under unstable conditions', aA, 'RSL', 0), &
      varAttr('L_MOD_RSL', 'm', f104, 'Obukhob length', aA, 'RSL', 0), &
      varAttr('zH_RSL', 'm', f104, 'canyon depth', aA, 'RSL', 0), &
      ! varAttr('Lc_stab', 'm', f104, 'threshold of canopy drag length scale under stable conditions', aA, 'RSL', 0), &
      ! varAttr('Lc_unstab', 'm', f104, 'threshold of canopy drag length scale under unstable conditions', aA, 'RSL', 0), &
      varAttr('Lc', 'm', f104, 'canopy drag length scale', aA, 'RSL', 0), &
      varAttr('beta', 'm', f104, 'beta coefficient from Harman 2012', aA, 'RSL', 0), &
      varAttr('zd_RSL', 'm', f104, 'displacement height', aA, 'RSL', 0), &
      varAttr('z0_RSL', 'm', f104, 'roughness length', aA, 'RSL', 0), &
      varAttr('elm', 'm', f104, 'mixing length', aA, 'RSL', 0), &
      varAttr('Scc', '-', f104, 'Schmidt number for temperature and humidity', aA, 'RSL', 0), &
      varAttr('f', 'g kg-1', f104, 'H&F07 and H&F08 constants', aA, 'RSL', 0), &
      varAttr('UStar_RSL', 'm s-1', f104, 'friction velocity used in RSL', aA, 'RSL', 0), &
      varAttr('UStar_heat', 'm s-1', f104, 'friction velocity implied by RA_h', aA, 'RSL', 0), &
      varAttr('TStar_RSL', 'K', f104, 'friction temperature used in RSL', aA, 'RSL', 0), &
      varAttr('FAI', '-', f104, 'frontal area index', aA, 'RSL', 0), &
      varAttr('PAI', '-', f104, 'plan area index', aA, 'RSL', 0), &
      varAttr('flag_RSL', '-', f104, 'flag for RSL', aA, 'RSL', 0) &
      /

   ! debug info
   DATA(varListAll(n), &
        n=ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 &
        + ncolumnsdataOutBL - 5 + ncolumnsDataOutSnow - 5 + ncolumnsDataOutESTM - 5 &
        + ncolumnsDataOutDailyState - 5 &
        + ncolumnsDataOutRSL - 5 &
        + 1, &
        ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 &
        + ncolumnsdataOutBL - 5 + ncolumnsDataOutSnow - 5 + ncolumnsDataOutESTM - 5 &
        + ncolumnsDataOutDailyState - 5 &
        + ncolumnsDataOutRSL - 5 &
        + ncolumnsDataOutDebug - 5 &
        )/ &
      varAttr('RSS_Paved', 'm', f104, 'wetness adjusted RS for paved surface', aA, 'debug', 0), &
      varAttr('RSS_Bldgs', 'm', f104, 'wetness adjusted RS for building surface', aA, 'debug', 0), &
      varAttr('RSS_EveTr', 'm', f104, 'wetness adjusted RS for evergreen tree surface', aA, 'debug', 0), &
      varAttr('RSS_DecTr', 'm', f104, 'wetness adjusted RS for deciduous tree surface', aA, 'debug', 0), &
      varAttr('RSS_Grass', 'm', f104, 'wetness adjusted RS for grass surface', aA, 'debug', 0), &
      varAttr('RSS_BSoil', 'm', f104, 'wetness adjusted RS for bare soil surface', aA, 'debug', 0), &
      varAttr('RSS_Water', 'm', f104, 'wetness adjusted RS for water surface', aA, 'debug', 0), &
      varAttr('state_Paved', 'm', f104, 'surface wetness for paved surface', aA, 'debug', 0), &
      varAttr('state_Bldgs', 'm', f104, 'surface wetness for building surface', aA, 'debug', 0), &
      varAttr('state_EveTr', 'm', f104, 'surface wetness for evergreen tree surface', aA, 'debug', 0), &
      varAttr('state_DecTr', 'm', f104, 'surface wetness for deciduous tree surface', aA, 'debug', 0), &
      varAttr('state_Grass', 'm', f104, 'surface wetness for grass surface', aA, 'debug', 0), &
      varAttr('state_BSoil', 'm', f104, 'surface wetness for bare soil surface', aA, 'debug', 0), &
      varAttr('state_Water', 'm', f104, 'surface wetness for water surface', aA, 'debug', 0), &
      varAttr('RS', 'm', f104, 'RS', aA, 'debug', 0), &
      varAttr('RA', 'm', f104, 'RA', aA, 'debug', 0), &
      varAttr('RB', 'm', f104, 'RB', aA, 'debug', 0), &
      varAttr('RAsnow', 'm', f104, 'RA for snow', aA, 'debug', 0), &
      varAttr('vpd_hPa', 'm', f104, 'vapour pressure deficit', aA, 'debug', 0), &
      varAttr('lv_J_kg', 'm', f104, 'latent heat of vaporisation', aA, 'debug', 0), &
      varAttr('avdens', 'm', f104, 'air density', aA, 'debug', 0), &
      varAttr('avcp', 'm', f104, 'air heat capacity at constant pressure', aA, 'debug', 0), &
      varAttr('s_hPa', 'm', f104, 'Vapour pressure versus temperature slope in PM', aA, 'debug', 0), &
      varAttr('psyc_hPa', 'm', f104, 'Psychometric constant', aA, 'debug', 0) &
      /

   ! SPARTACUS info
   DATA(varListAll(n), &
      n=ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 &
      + ncolumnsdataOutBL - 5 + ncolumnsDataOutSnow - 5 + ncolumnsDataOutESTM - 5 &
      + ncolumnsDataOutDailyState - 5 &
      + ncolumnsDataOutRSL - 5 &
      + ncolumnsDataOutDebug - 5 &
      + 1, &
      ncolumnsDataOutSUEWS + ncolumnsdataOutBEERS - 5 &
      + ncolumnsdataOutBL - 5 + ncolumnsDataOutSnow - 5 + ncolumnsDataOutESTM - 5 &
      + ncolumnsDataOutDailyState - 5 &
      + ncolumnsDataOutRSL - 5 &
      + ncolumnsDataOutDebug - 5 &
      + ncolumnsDataOutSPARTACUS - 5 &
      )/ &
      varAttr('alb', '-', f104, 'bulk albedo from spartacus', aA, 'SPARTACUS', 0), &
      varAttr('emis', '-', f104, 'bulk emissivity from spartacus', aA, 'SPARTACUS', 0), &
      varAttr('Lemission', 'W m-2', f104, 'lw emission from spartacus', aA, 'SPARTACUS', 0), &
      varAttr('Lup', 'W m-2', f104, 'lw upward flux from spartacus', aA, 'SPARTACUS', 0), &
      varAttr('Kup', 'W m-2', f104, 'bulk albedo from spartacus', aA, 'SPARTACUS', 0), &
      varAttr('Qn', 'W m-2', f104, 'bulk emissivity from spartacus', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs1', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 1', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs2', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 2', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs3', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 3', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs4', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 4', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs5', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 5', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs6', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 6', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs7', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 7', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs8', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 8', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs9', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 9', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs10', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 10', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs11', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 11', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs12', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 12', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs13', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 13', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs14', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 14', aA, 'SPARTACUS', 0), &
      varAttr('LCAAbs15', 'W m-2', f104, 'lw clear air absorption - SPARTACUS level 15', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet1', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 1', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet2', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 2', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet3', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 3', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet4', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 4', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet5', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 5', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet6', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 6', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet7', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 7', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet8', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 8', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet9', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 9', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet10', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 10', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet11', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 11', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet12', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 12', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet13', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 13', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet14', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 14', aA, 'SPARTACUS', 0), &
      varAttr('LWallNet15', 'W m-2', f104, 'lw net radiation at wall - SPARTACUS level 15', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet1', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 1', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet2', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 2', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet3', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 3', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet4', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 4', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet5', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 5', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet6', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 6', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet7', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 7', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet8', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 8', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet9', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 9', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet10', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 10', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet11', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 11', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet12', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 12', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet13', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 13', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet14', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 14', aA, 'SPARTACUS', 0), &
      varAttr('LRfNet15', 'W m-2', f104, 'lw net radiation at roof - SPARTACUS level 15', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn1', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 1', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn2', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 2', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn3', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 3', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn4', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 4', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn5', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 5', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn6', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 6', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn7', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 7', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn8', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 8', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn9', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 9', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn10', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 10', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn11', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 11', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn12', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 12', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn13', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 13', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn14', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 14', aA, 'SPARTACUS', 0), &
      varAttr('LRfIn15', 'W m-2', f104, 'lw radiation into roof - SPARTACUS level 15', aA, 'SPARTACUS', 0), &
      varAttr('LTopNet', 'W m-2', f104, 'lw net radiation at top-of-canopy', aA, 'SPARTACUS', 0), &
      varAttr('LGrndNet', 'W m-2', f104, 'lw net radiation at ground', aA, 'SPARTACUS', 0), &
      varAttr('LTopDn', 'W m-2', f104, 'lw downwelling radiation at top-of-canopy', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs1', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 1', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs2', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 2', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs3', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 3', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs4', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 4', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs5', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 5', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs6', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 6', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs7', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 7', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs8', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 8', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs9', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 9', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs10', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 10', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs11', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 11', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs12', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 12', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs13', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 13', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs14', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 14', aA, 'SPARTACUS', 0), &
      varAttr('KCAAbs15', 'W m-2', f104, 'sw clear air absorption - SPARTACUS level 15', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet1', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 1', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet2', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 2', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet3', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 3', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet4', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 4', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet5', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 5', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet6', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 6', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet7', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 7', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet8', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 8', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet9', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 9', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet10', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 10', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet11', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 11', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet12', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 12', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet13', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 13', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet14', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 14', aA, 'SPARTACUS', 0), &
      varAttr('KWallNet15', 'W m-2', f104, 'sw net radiation at wall - SPARTACUS level 15', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet1', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 1', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet2', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 2', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet3', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 3', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet4', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 4', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet5', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 5', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet6', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 6', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet7', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 7', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet8', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 8', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet9', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 9', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet10', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 10', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet11', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 11', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet12', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 12', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet13', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 13', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet14', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 14', aA, 'SPARTACUS', 0), &
      varAttr('KRfNet15', 'W m-2', f104, 'sw net radiation at roof - SPARTACUS level 15', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn1', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 1', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn2', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 2', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn3', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 3', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn4', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 4', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn5', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 5', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn6', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 6', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn7', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 7', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn8', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 8', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn9', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 9', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn10', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 10', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn11', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 11', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn12', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 12', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn13', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 13', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn14', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 14', aA, 'SPARTACUS', 0), &
      varAttr('KRfIn15', 'W m-2', f104, 'sw radiation into roof - SPARTACUS level 15', aA, 'SPARTACUS', 0), &
      varAttr('KTopDnDir', 'W m-2', f104, 'sw downwelling direct radiation at top-of-canopy', aA, 'SPARTACUS', 0), &
      varAttr('KTopNet', 'W m-2', f104, 'sw net radiation at top-of-canopy', aA, 'SPARTACUS', 0), &
      varAttr('KGrndDnDir', 'W m-2', f104, 'sw downwelling direct radiation at ground', aA, 'SPARTACUS', 0), &
      varAttr('KGrndNet', 'W m-2', f104, 'sw net radiation at ground', aA, 'SPARTACUS', 0) &
      /

CONTAINS
   ! main wrapper that handles both txt and nc files
   SUBROUTINE SUEWS_Output(irMax, iv, Gridiv, iyr)
      IMPLICIT NONE
      INTEGER, INTENT(in) :: irMax
! #ifdef nc
!       INTEGER, INTENT(in), OPTIONAL ::iv, Gridiv, iyr
! #else
      INTEGER, INTENT(in) ::iv, Gridiv, iyr
! #endif

      INTEGER :: n_group_use, err, outLevel, i
      TYPE(varAttr), DIMENSION(:), ALLOCATABLE::varListX
      CHARACTER(len=10) :: groupList0(9)
      CHARACTER(len=10), DIMENSION(:), ALLOCATABLE :: grpList
      LOGICAL :: groupCond(9)

      ! determine outLevel
      SELECT CASE (WriteOutOption)
      CASE (0) !all (not snow-related)
         outLevel = 1
      CASE (1) !all plus snow-related
         outLevel = 2
      CASE (2) !minimal output
         outLevel = 0
      END SELECT

      ! determine groups to output
      ! TODO: needs to be smarter, automate this filtering
      groupList0(1) = 'SUEWS'
      groupList0(2) = 'BEERS'
      groupList0(3) = 'BL'
      groupList0(4) = 'snow'
      groupList0(5) = 'ESTM'
      groupList0(6) = 'DailyState'
      groupList0(7) = 'RSL'
      groupList0(8) = 'debug'
      groupList0(9) = 'SPARTACUS'
      groupCond = [ &
                  .TRUE., &
                  .TRUE., &
                  CBLuse >= 1, &
                  SnowUse >= 1, &
                  StorageHeatMethod == 4 .OR. StorageHeatMethod == 14, &
                  .TRUE., &
                  .TRUE., &
                  .TRUE., &
                  .TRUE. &
                  ]
      n_group_use = COUNT(groupCond)

      ! PRINT*, grpList0,xx

      ALLOCATE (grpList(n_group_use), stat=err)
      IF (err /= 0) PRINT *, "grpList: Allocation request denied"

      grpList = PACK(groupList0, mask=groupCond)

      ! PRINT*, grpList,SIZE(grpList, dim=1)

      ! loop over all groups
      DO i = 1, SIZE(grpList), 1
         !PRINT*, 'i',i
         n_group_use = COUNT(varListAll%group == TRIM(grpList(i)), dim=1)
         !  PRINT*, 'number of variables:',xx, 'in group: ',grpList(i)
         !  print*, 'all group names: ',varList%group
         ALLOCATE (varListX(5 + n_group_use), stat=err)
         IF (err /= 0) PRINT *, "varListX: Allocation request denied"
         ! datetime
         varListX(1:5) = varListAll(1:5)
         ! variable
         varListX(6:5 + n_group_use) = PACK(varListAll, mask=(varListAll%group == TRIM(grpList(i))))

         IF (TRIM(varListX(SIZE(varListX))%group) /= 'DailyState') THEN
            ! all output arrays but DailyState
            ! all output frequency option:
            ! as forcing:
            IF (ResolutionFilesOut == Tstep .OR. KeepTstepFilesOut == 1) THEN
               CALL SUEWS_Output_txt_grp(iv, irMax, iyr, varListX, Gridiv, outLevel, Tstep)
            END IF
            !  as specified ResolutionFilesOut:
            IF (ResolutionFilesOut /= Tstep) THEN
               CALL SUEWS_Output_txt_grp(iv, irMax, iyr, varListX, Gridiv, outLevel, ResolutionFilesOut)
            END IF
         ELSE
            !  DailyState array, which does not need aggregation

            CALL SUEWS_Output_txt_grp(iv, irMax, iyr, varListX, Gridiv, outLevel, Tstep)

         END IF

         IF (ALLOCATED(varListX)) DEALLOCATE (varListX, stat=err)
         IF (err /= 0) PRINT *, "varListX: Deallocation request denied"
         !  PRINT*, 'i',i,'end'

      END DO
   END SUBROUTINE SUEWS_Output

   ! output wrapper function for one group
   SUBROUTINE SUEWS_Output_txt_grp(iv, irMax, iyr, varListX, Gridiv, outLevel, outFreq_s)
      IMPLICIT NONE

      TYPE(varAttr), DIMENSION(:), INTENT(in)::varListX
      INTEGER, INTENT(in) :: iv, irMax, iyr, Gridiv, outLevel, outFreq_s

      INTEGER :: err

      INTEGER, DIMENSION(:), ALLOCATABLE  ::id_seq ! id sequence as in the dataOutX/dataOutX_agg
      REAL(KIND(1D0)), DIMENSION(:, :), ALLOCATABLE::dataOutX
      REAL(KIND(1D0)), DIMENSION(:, :), ALLOCATABLE::dataOutX_agg

      IF (.NOT. ALLOCATED(dataOutX)) THEN
         ALLOCATE (dataOutX(irMax, SIZE(varListX)), stat=err)
         IF (err /= 0) PRINT *, "dataOutX: Allocation request denied"
      END IF

      ! determine dataOutX array according to variable group
      SELECT CASE (TRIM(varListX(SIZE(varListX))%group))
      CASE ('SUEWS') !default
         dataOutX = dataOutSUEWS(1:irMax, 1:SIZE(varListX), Gridiv)

      CASE ('BEERS') !SOLWEIG
         dataOutX = dataOutBEERS(1:irMax, 1:SIZE(varListX), Gridiv)
         ! dataOutX = dataOutSOLWEIG(1:irMax, 1:SIZE(varListX), Gridiv)

      CASE ('BL') !BL
         dataOutX = dataOutBL(1:irMax, 1:SIZE(varListX), Gridiv)

      CASE ('snow')    !snow
         dataOutX = dataOutSnow(1:irMax, 1:SIZE(varListX), Gridiv)

      CASE ('ESTM')    !ESTM
         dataOutX = dataOutESTM(1:irMax, 1:SIZE(varListX), Gridiv)

      CASE ('RSL')    !RSL
         dataOutX = dataOutRSL(1:irMax, 1:SIZE(varListX), Gridiv)

      CASE ('debug')    !debug
         dataOutX = dataOutDebug(1:irMax, 1:SIZE(varListX), Gridiv)

      CASE ('SPARTACUS')    !SPARTACUS
         dataOutX = dataOutSPARTACUS(1:irMax, 1:SIZE(varListX), Gridiv)

      CASE ('DailyState')    !DailyState
         ! get correct day index
         CALL unique(INT(PACK(dataOutSUEWS(1:irMax, 2, Gridiv), &
                              mask=(dataOutSUEWS(1:irMax, 3, Gridiv) == 23 &
                                    .AND. dataOutSUEWS(1:irMax, 4, Gridiv) == (nsh - 1.)/nsh*60))), &
                     id_seq)

         IF (ALLOCATED(dataOutX)) THEN
            DEALLOCATE (dataOutX)
            IF (err /= 0) PRINT *, "dataOutX: Deallocation request denied"
         END IF

         IF (.NOT. ALLOCATED(dataOutX)) THEN
            ALLOCATE (dataOutX(SIZE(id_seq), SIZE(varListX)), stat=err)
            IF (err /= 0) PRINT *, "dataOutX: Allocation request denied"
         END IF

         dataOutX = dataOutDailyState(id_seq, 1:SIZE(varListX), Gridiv)
         ! print*, id_seq
         ! print*, dataOutDailyState(id_seq,1:SIZE(varListX),Gridiv)
         ! print*, 1/(nsh-nsh)
      END SELECT

      ! aggregation:
      ! aggregation is done for every group but 'DailyState'
      IF (TRIM(varListX(SIZE(varListX))%group) /= 'DailyState') THEN

         CALL SUEWS_Output_Agg(dataOutX_agg, dataOutX, varListX, irMax, outFreq_s)
      ELSE
         IF (.NOT. ALLOCATED(dataOutX_agg)) THEN
            ALLOCATE (dataOutX_agg(SIZE(dataOutX, dim=1), SIZE(varListX)), stat=err)
            IF (err /= 0) PRINT *, ": Allocation request denied"
         END IF
         dataOutX_agg = dataOutX
      END IF

      ! output:
      ! initialise file when processing first metblock
      IF (iv == 1) CALL SUEWS_Output_Init(dataOutX_agg, varListX, iyr, Gridiv, outLevel)

      ! append the aggregated data to the specific txt file
      CALL SUEWS_Write_txt(dataOutX_agg, varListX, iyr, Gridiv, outLevel)

   END SUBROUTINE SUEWS_Output_txt_grp

   ! initialise an output file with file name and headers
   SUBROUTINE SUEWS_Output_Init(dataOutX, varList, iyr, Gridiv, outLevel)
      IMPLICIT NONE
      REAL(KIND(1D0)), DIMENSION(:, :), INTENT(in)::dataOutX
      TYPE(varAttr), DIMENSION(:), INTENT(in)::varList
      INTEGER, INTENT(in) :: iyr, Gridiv, outLevel

      TYPE(varAttr), DIMENSION(:), ALLOCATABLE::varListSel
      INTEGER :: xx, err, fn, i, nargs
      CHARACTER(len=365) :: FileOutX
      CHARACTER(len=3) :: itextX
      CHARACTER(len=6) :: args(5)
      CHARACTER(len=16*SIZE(varList)) :: FormatOut
      CHARACTER(len=16) :: formatX
      CHARACTER(len=16), DIMENSION(:), ALLOCATABLE:: headerOut

      ! select variables to output
      xx = COUNT((varList%level <= outLevel), dim=1)
      WRITE (itextX, '(i3)') xx
      ALLOCATE (varListSel(xx), stat=err)
      IF (err /= 0) PRINT *, "varListSel: Allocation request denied"
      varListSel = PACK(varList, mask=(varList%level <= outLevel))

      ! generate file name
      CALL filename_gen(dataOutX, varList, iyr, Gridiv, FileOutX)

      ! store right-aligned headers
      ALLOCATE (headerOut(xx), stat=err)
      IF (err /= 0) PRINT *, "headerOut: Allocation request denied"

      ! create format string:
      DO i = 1, SIZE(varListSel)
         CALL parse(varListSel(i)%fmt, 'if.,', args, nargs)
         formatX = ADJUSTL('(a'//TRIM(args(2))//',1x)')
         ! adjust headers to right-aligned
         WRITE (headerOut(i), formatX) ADJUSTR(TRIM(ADJUSTL(varListSel(i)%header)))
         IF (i == 1) THEN
            FormatOut = ADJUSTL(TRIM(formatX))
         ELSE
            FormatOut = TRIM(FormatOut)//' '//ADJUSTL(TRIM(formatX))
         END IF
      END DO
      FormatOut = '('//TRIM(ADJUSTL(FormatOut))//')'

      ! create file
      fn = 9
      OPEN (fn, file=TRIM(ADJUSTL(FileOutX)), status='unknown')
      ! PRINT*, 'FileOutX in SUEWS_Output_Init: ',FileOutX

      ! write out headers
      WRITE (fn, FormatOut) headerOut
      CLOSE (fn)

      ! write out format file
      CALL formatFile_gen(dataOutX, varList, iyr, Gridiv, outLevel)

      ! clean up
      IF (ALLOCATED(varListSel)) DEALLOCATE (varListSel, stat=err)
      IF (err /= 0) PRINT *, "varListSel: Deallocation request denied"
      IF (ALLOCATED(headerOut)) DEALLOCATE (headerOut, stat=err)
      IF (err /= 0) PRINT *, "headerOut: Deallocation request denied"

   END SUBROUTINE SUEWS_Output_Init

   ! generate output format file
   SUBROUTINE formatFile_gen(dataOutX, varList, iyr, Gridiv, outLevel)
      IMPLICIT NONE
      REAL(KIND(1D0)), DIMENSION(:, :), INTENT(in)::dataOutX
      TYPE(varAttr), DIMENSION(:), INTENT(in)::varList
      INTEGER, INTENT(in) :: iyr, Gridiv, outLevel

      TYPE(varAttr), DIMENSION(:), ALLOCATABLE::varListSel
      INTEGER :: xx, err, fn, i
      CHARACTER(len=365) :: FileOutX
      CHARACTER(len=100*300) :: str_cat
      CHARACTER(len=100) :: str_x = ''
      CHARACTER(len=3) :: itextX

      ! get filename
      CALL filename_gen(dataOutX, varList, iyr, Gridiv, FileOutX, 1)

      !select variables to output
      xx = COUNT((varList%level <= outLevel), dim=1)
      ALLOCATE (varListSel(xx), stat=err)
      IF (err /= 0) PRINT *, "varListSel: Allocation request denied"
      varListSel = PACK(varList, mask=(varList%level <= outLevel))

      ! create file
      fn = 9
      OPEN (fn, file=TRIM(ADJUSTL(FileOutX)), status='unknown')

      ! write out format strings
      ! column number:
      str_cat = ''
      DO i = 1, SIZE(varListSel)
         WRITE (itextX, '(i3)') i
         IF (i == 1) THEN
            str_cat = TRIM(ADJUSTL(itextX))
         ELSE
            str_cat = TRIM(str_cat)//';'//ADJUSTL(itextX)
         END IF
      END DO
      WRITE (fn, '(a)') TRIM(str_cat)

      ! header:
      str_cat = ''
      DO i = 1, SIZE(varListSel)
         str_x = varListSel(i)%header
         IF (i == 1) THEN
            str_cat = TRIM(ADJUSTL(str_x))
         ELSE
            str_cat = TRIM(str_cat)//';'//ADJUSTL(str_x)
         END IF
      END DO
      WRITE (fn, '(a)') TRIM(str_cat)

      ! long name:
      str_cat = ''
      DO i = 1, SIZE(varListSel)
         str_x = varListSel(i)%longNm
         IF (i == 1) THEN
            str_cat = TRIM(ADJUSTL(str_x))
         ELSE
            str_cat = TRIM(str_cat)//';'//ADJUSTL(str_x)
         END IF
      END DO
      WRITE (fn, '(a)') TRIM(str_cat)

      ! unit:
      str_cat = ''
      DO i = 1, SIZE(varListSel)
         str_x = varListSel(i)%unit
         IF (i == 1) THEN
            str_cat = TRIM(ADJUSTL(str_x))
         ELSE
            str_cat = TRIM(str_cat)//';'//ADJUSTL(str_x)
         END IF
      END DO
      WRITE (fn, '(a)') TRIM(str_cat)

      ! format:
      str_cat = ''
      DO i = 1, SIZE(varListSel)
         str_x = varListSel(i)%fmt
         IF (i == 1) THEN
            str_cat = TRIM(ADJUSTL(str_x))
         ELSE
            str_cat = TRIM(str_cat)//';'//ADJUSTL(str_x)
         END IF
      END DO
      WRITE (fn, '(a)') TRIM(str_cat)

      ! aggregation method:
      str_cat = ''
      DO i = 1, SIZE(varListSel)
         str_x = varListSel(i)%aggreg
         IF (i == 1) THEN
            str_cat = TRIM(ADJUSTL(str_x))
         ELSE
            str_cat = TRIM(str_cat)//';'//ADJUSTL(str_x)
         END IF
      END DO
      WRITE (fn, '(a)') TRIM(str_cat)

      ! close file
      CLOSE (fn)

      ! clean up
      IF (ALLOCATED(varListSel)) DEALLOCATE (varListSel, stat=err)
      IF (err /= 0) PRINT *, "varListSel: Deallocation request denied"

   END SUBROUTINE formatFile_gen

   ! aggregate data to specified resolution
   SUBROUTINE SUEWS_Output_Agg(dataOut_agg, dataOutX, varList, irMax, outFreq_s)
      IMPLICIT NONE
      REAL(KIND(1D0)), DIMENSION(:, :), INTENT(in)::dataOutX
      TYPE(varAttr), DIMENSION(:), INTENT(in)::varList
      INTEGER, INTENT(in) :: irMax, outFreq_s
      REAL(KIND(1D0)), DIMENSION(:, :), ALLOCATABLE, INTENT(out)::dataOut_agg

      INTEGER ::  nlinesOut, i, j, x
      REAL(KIND(1D0))::dataOut_aggX(1:SIZE(varList))
      REAL(KIND(1D0)), DIMENSION(:, :), ALLOCATABLE::dataOut_agg0
      nlinesOut = INT(nsh/(60.*60/outFreq_s))
      ! nGrid=SIZE(dataOutX, dim=3)

      ALLOCATE (dataOut_agg(INT(irMax/nlinesOut), SIZE(varList)))
      ALLOCATE (dataOut_agg0(nlinesOut, SIZE(varList)))

      DO i = nlinesOut, irMax, nlinesOut
         x = i/nlinesOut
         dataOut_agg0 = dataOutX(i - nlinesOut + 1:i, :)
         DO j = 1, SIZE(varList), 1
            ! aggregating different variables
            SELECT CASE (varList(j)%aggreg)
            CASE (aT) !time columns, aT
               dataOut_aggX(j) = dataOut_agg0(nlinesOut, j)
            CASE (aA) !average, aA
               dataOut_aggX(j) = SUM(dataOut_agg0(:, j))/nlinesOut
            CASE (aS) !sum, aS
               dataOut_aggX(j) = SUM(dataOut_agg0(:, j))
            CASE (aL) !last value, aL
               dataOut_aggX(j) = dataOut_agg0(nlinesOut, j)
            END SELECT

            IF (Diagnose == 1 .AND. i == irMax) THEN
               ! IF ( i==irMax ) THEN
               PRINT *, 'raw data of ', j, ':'
               PRINT *, dataOut_agg0(:, j)
               PRINT *, 'aggregated with method: ', varList(j)%aggreg
               PRINT *, dataOut_aggX(j)
               PRINT *, ''
            END IF
         END DO
         dataOut_agg(x, :) = dataOut_aggX
      END DO

   END SUBROUTINE SUEWS_Output_Agg

   ! append output data to the specific file at the specified outLevel
   SUBROUTINE SUEWS_Write_txt(dataOutX, varList, iyr, Gridiv, outLevel)
      IMPLICIT NONE
      REAL(KIND(1D0)), DIMENSION(:, :), INTENT(in)::dataOutX
      TYPE(varAttr), DIMENSION(:), INTENT(in)::varList
      INTEGER, INTENT(in) :: iyr, Gridiv, outLevel

      REAL(KIND(1D0)), DIMENSION(:, :), ALLOCATABLE::dataOutSel
      TYPE(varAttr), DIMENSION(:), ALLOCATABLE::varListSel
      CHARACTER(len=365) :: FileOutX
      INTEGER :: fn, i, xx, err
      INTEGER :: sizeVarListSel, sizedataOutX
      CHARACTER(len=12*SIZE(varList)) :: FormatOut
      ! LOGICAL :: initQ_file
      FormatOut = ''

      IF (Diagnose == 1) WRITE (*, *) 'Writting data of group: ', varList(SIZE(varList))%group

      !select variables to output
      sizeVarListSel = COUNT((varList%level <= outLevel), dim=1)
      ALLOCATE (varListSel(sizeVarListSel), stat=err)
      IF (err /= 0) PRINT *, "varListSel: Allocation request denied"
      varListSel = PACK(varList, mask=(varList%level <= outLevel))

      ! copy data accordingly
      sizedataOutX = SIZE(dataOutX, dim=1)
      ALLOCATE (dataOutSel(sizedataOutX, sizeVarListSel), stat=err)
      IF (err /= 0) PRINT *, "dataOutSel: Allocation request denied"
      ! print*, SIZE(varList%level),PACK((/(i,i=1,SIZE(varList%level))/), varList%level <= outLevel)
      ! print*, irMax,shape(dataOutX)
      dataOutSel = dataOutX(:, PACK((/(i, i=1, SIZE(varList%level))/), varList%level <= outLevel))

      ! create format string:
      DO i = 1, sizeVarListSel
         ! PRINT*,''
         ! PRINT*,i
         ! PRINT*, LEN_TRIM(FormatOut),TRIM(FormatOut)
         ! PRINT*, LEN_TRIM(TRIM(FormatOut)//','),TRIM(FormatOut)//','
         IF (i == 1) THEN
            ! FormatOut=ADJUSTL(varListSel(i)%fmt)
            FormatOut = varListSel(i)%fmt
         ELSE

            ! FormatOut=TRIM(FormatOut)//','//ADJUSTL(varListSel(i)%fmt)
            FormatOut = TRIM(FormatOut)//','//TRIM(varListSel(i)%fmt)
         END IF
         ! PRINT*,''
         ! PRINT*,i
         ! PRINT*, 'FormatOut',FormatOut
      END DO
      FormatOut = '('//TRIM(ADJUSTL(FormatOut))//')'

      ! get filename
      CALL filename_gen(dataOutSel, varListSel, iyr, Gridiv, FileOutX)
      ! PRINT*, 'FileOutX in SUEWS_Write_txt: ',FileOutX

      ! test if FileOutX has been initialised
      ! IF ( .NOT. initQ_file(FileOutX) ) THEN
      !    CALL SUEWS_Output_Init(dataOutSel,varListSel,Gridiv,outLevel)
      ! END IF

      ! write out data
      fn = 50
      OPEN (fn, file=TRIM(FileOutX), position='append')!,err=112)
      DO i = 1, sizedataOutX
         ! PRINT*, 'Writting',i
         ! PRINT*, 'FormatOut',FormatOut
         ! PRINT*, dataOutSel(i,1:sizeVarListSel)
         WRITE (fn, FormatOut) &
            (INT(dataOutSel(i, xx)), xx=1, 4), &
            (dataOutSel(i, xx), xx=5, sizeVarListSel)
      END DO
      CLOSE (fn)

      IF (ALLOCATED(varListSel)) DEALLOCATE (varListSel, stat=err)
      IF (err /= 0) PRINT *, "varListSel: Deallocation request denied"

      IF (ALLOCATED(dataOutSel)) DEALLOCATE (dataOutSel, stat=err)
      IF (err /= 0) PRINT *, "dataOutSel: Deallocation request denied"

   END SUBROUTINE SUEWS_Write_txt

   SUBROUTINE filename_gen(dataOutX, varList, iyr, Gridiv, FileOutX, opt_fmt)
      USE datetime_module

      IMPLICIT NONE
      REAL(KIND(1D0)), DIMENSION(:, :), INTENT(in)::dataOutX ! to determine year & output frequency
      TYPE(varAttr), DIMENSION(:), INTENT(in)::varList ! to determine output group
      INTEGER, INTENT(in) :: iyr ! to determine year
      INTEGER, INTENT(in) :: Gridiv ! to determine grid name as in SiteSelect
      INTEGER, INTENT(in), OPTIONAL :: opt_fmt ! to determine if a format file
      CHARACTER(len=365), INTENT(out) :: FileOutX ! the output file name

      CHARACTER(len=20):: str_out_min, str_grid, &
                          str_date, str_year, str_DOY, str_grp, str_sfx
      INTEGER :: year_int, DOY_int, val_fmt, delta_t_min
      TYPE(datetime) :: dt1, dt2
      TYPE(timedelta) :: dt_x

      ! initialise with a default value
      val_fmt = -999

      IF (PRESENT(opt_fmt)) val_fmt = opt_fmt

      ! PRINT*, varList(:)%header
      ! PRINT*, 'dataOutX(1)',dataOutX(1,:)

      ! date:
      DOY_int = INT(dataOutX(1, 2))
      WRITE (str_DOY, '(i3.3)') DOY_int

! #ifdef nc
!       ! year for nc use that in dataOutX
!       year_int = INT(dataOutX(1, 1))
!       WRITE (str_year, '(i4)') year_int
!       str_date = '_'//TRIM(ADJUSTL(str_year))
!       ! add DOY as a specifier
!       IF (ncMode == 1) str_date = TRIM(ADJUSTL(str_date))//TRIM(ADJUSTL(str_DOY))
! #endif

      ! year for txt use specified value to avoid conflicts when crossing years
      year_int = iyr
      WRITE (str_year, '(i4)') year_int
      str_date = '_'//TRIM(ADJUSTL(str_year))

      ! output frequency in minute:
      IF (varList(6)%group == 'DailyState') THEN
         str_out_min = '' ! ignore this for DailyState
      ELSE
         ! derive output frequency from output arrays
         ! dt_x=
         dt1 = datetime(INT(dataOutX(1, 1)), 1, 1) + &
               timedelta(days=INT(dataOutX(1, 2) - 1), &
                         hours=INT(dataOutX(1, 3)), &
                         minutes=INT(dataOutX(1, 4)))

         dt2 = datetime(INT(dataOutX(2, 1)), 1, 1) + &
               timedelta(days=INT(dataOutX(2, 2) - 1), &
                         hours=INT(dataOutX(2, 3)), &
                         minutes=INT(dataOutX(2, 4)))

         dt_x = dt2 - dt1
         delta_t_min = INT(dt_x%total_seconds()/60)
         WRITE (str_out_min, '(i4)') delta_t_min
         str_out_min = '_'//TRIM(ADJUSTL(str_out_min))
      END IF

      ! group: output type
      str_grp = varList(6)%group
      IF (LEN(TRIM(str_grp)) > 0) str_grp = '_'//TRIM(ADJUSTL(str_grp))

      ! grid name:
      WRITE (str_grid, '(i10)') GridIDmatrix(Gridiv)
! #ifdef nc
!       IF (ncMode == 1) str_grid = '' ! grid name not needed by nc files
! #endif

      ! suffix:
      str_sfx = '.txt'
! #ifdef nc
!       IF (ncMode == 1) str_sfx = '.nc'
! #endif

      ! filename: FileOutX
      FileOutX = TRIM(FileOutputPath)// &
                 TRIM(FileCode)// &
                 TRIM(ADJUSTL(str_grid))// &
                 TRIM(ADJUSTL(str_date))// &
                 TRIM(ADJUSTL(str_grp))// &
                 TRIM(ADJUSTL(str_out_min))// &
                 TRIM(ADJUSTL(str_sfx))

      ! filename: format
      IF (val_fmt == 1) THEN
         FileOutX = TRIM(FileOutputPath)// &
                    TRIM(FileCode)// &
                    TRIM(ADJUSTL(str_grp))// &
                    '_OutputFormat.txt'
      END IF

   END SUBROUTINE filename_gen

   SUBROUTINE unique(vec, vec_unique)
      ! Return only the unique values from vec.

      IMPLICIT NONE

      INTEGER, DIMENSION(:), INTENT(in) :: vec
      INTEGER, DIMENSION(:), ALLOCATABLE, INTENT(out) :: vec_unique

      INTEGER :: i, num
      LOGICAL, DIMENSION(SIZE(vec)) :: mask

      mask = .FALSE.

      DO i = 1, SIZE(vec)

         !count the number of occurrences of this element:
         num = COUNT(vec(i) == vec)

         IF (num == 1) THEN
            !there is only one, flag it:
            mask(i) = .TRUE.
         ELSE
            !flag this value only if it hasn't already been flagged:
            IF (.NOT. ANY(vec(i) == vec .AND. mask)) mask(i) = .TRUE.
         END IF

      END DO

      !return only flagged elements:
      ALLOCATE (vec_unique(COUNT(mask)))
      vec_unique = PACK(vec, mask)

      !if you also need it sorted, then do so.
      ! For example, with slatec routine:
      !call ISORT (vec_unique, [0], size(vec_unique), 1)

   END SUBROUTINE unique

   ! test if a txt file has been initialised
   LOGICAL FUNCTION initQ_file(FileName)
      IMPLICIT NONE
      CHARACTER(len=365), INTENT(in) :: FileName ! the output file name
      LOGICAL :: existQ
      CHARACTER(len=1000) :: longstring

      INQUIRE (file=TRIM(FileName), exist=existQ)
      IF (existQ) THEN
         OPEN (10, file=TRIM(FileName))
         READ (10, '(a)') longstring
         ! print*, 'longstring: ',longstring
         IF (VERIFY(longstring, 'Year') == 0) initQ_file = .FALSE.
         CLOSE (unit=10)
      ELSE
         initQ_file = .FALSE.
      END IF

   END FUNCTION initQ_file

   !========================================================================================
   FUNCTION count_lines(filename) RESULT(nlines)
      ! count the number of valid lines in a file
      ! invalid line starting with -9

      !========================================================================================
      IMPLICIT NONE
      CHARACTER(len=*)    :: filename
      INTEGER             :: nlines
      INTEGER             :: io, iv

      OPEN (10, file=filename, iostat=io, status='old')

      ! if io error found, report iostat and exit
      IF (io /= 0) THEN
         PRINT *, 'io', io, 'for', filename
         STOP 'Cannot open file! '
      END IF

      nlines = 0
      DO
         READ (10, *, iostat=io) iv
         IF (io < 0 .OR. iv == -9) EXIT

         nlines = nlines + 1
      END DO
      CLOSE (10)
      nlines = nlines - 1 ! skip header
   END FUNCTION count_lines

   !===========================================================================!
   ! write the output of final SUEWS results in netCDF
   !   with spatial layout of QGIS convention
   ! the spatial matrix arranges successive rows down the page (i.e., north to south)
   !   and succesive columns across (i.e., west to east)
   ! the output file frequency is the same as metblocks in the main SUEWS loop
   !===========================================================================!

! #ifdef nc

!    SUBROUTINE SUEWS_Output_nc_grp(irMax, varList, outLevel, outFreq_s)
!       IMPLICIT NONE

!       TYPE(varAttr), DIMENSION(:), INTENT(in)::varList
!       INTEGER, INTENT(in) :: irMax, outLevel, outFreq_s

!       REAL(KIND(1d0)), ALLOCATABLE::dataOutX(:, :, :)
!       REAL(KIND(1d0)), ALLOCATABLE::dataOutX_agg(:, :, :), dataOutX_agg0(:, :)
!       INTEGER :: iGrid, err, idMin, idMax
!       INTEGER, DIMENSION(:), ALLOCATABLE  ::id_seq

!       IF (.NOT. ALLOCATED(dataOutX)) THEN
!          ALLOCATE (dataOutX(irMax, SIZE(varList), NumberOfGrids), stat=err)
!          IF (err /= 0) PRINT *, "dataOutX: Allocation request denied"
!       ENDIF

!       ! determine dataOutX array according to variable group
!       SELECT CASE (TRIM(varList(SIZE(varList))%group))
!       CASE ('SUEWS') !default
!          dataOutX = dataOutSUEWS(1:irMax, 1:SIZE(varList), :)

!       CASE ('BEERS') !SOLWEIG
!          ! todo: inconsistent data structure
!          dataOutX = dataOutSOLWEIG(1:irMax, 1:SIZE(varList), :)

!       CASE ('BL') !BL
!          dataOutX = dataOutBL(1:irMax, 1:SIZE(varList), :)

!       CASE ('snow')    !snow
!          dataOutX = dataOutSnow(1:irMax, 1:SIZE(varList), :)

!       CASE ('ESTM')    !ESTM
!          dataOutX = dataOutESTM(1:irMax, 1:SIZE(varList), :)

!       CASE ('DailyState')    !DailyState
!          ! get correct day index
!          CALL unique(INT(PACK(dataOutSUEWS(1:irMax, 2, 1), &
!                               mask=(dataOutSUEWS(1:irMax, 3, Gridiv) == 23 &
!                                     .AND. dataOutSUEWS(1:irMax, 4, Gridiv) == (nsh - 1)/nsh*60))), &
!                      id_seq)
!          IF (ALLOCATED(dataOutX)) THEN
!             DEALLOCATE (dataOutX)
!             IF (err /= 0) PRINT *, "dataOutX: Deallocation request denied"
!          ENDIF

!          IF (.NOT. ALLOCATED(dataOutX)) THEN
!             ALLOCATE (dataOutX(SIZE(id_seq), SIZE(varList), NumberOfGrids), stat=err)
!             IF (err /= 0) PRINT *, "dataOutX: Allocation request denied"
!          ENDIF

!          dataOutX = dataOutDailyState(id_seq, 1:SIZE(varList), :)
!          ! print*, 'idMin line',dataOutX(idMin,1:4,1)
!          ! print*, 'idMax line',dataOutX(idMax,1:4,1)

!       END SELECT

!       ! aggregation:
!       IF (TRIM(varList(SIZE(varList))%group) /= 'DailyState') THEN
!          DO iGrid = 1, NumberOfGrids
!             CALL SUEWS_Output_Agg(dataOutX_agg0, dataOutX(:, :, iGrid), varList, irMax, outFreq_s)
!             IF (.NOT. ALLOCATED(dataOutX_agg)) THEN
!                ALLOCATE (dataOutX_agg(SIZE(dataOutX_agg0, dim=1), SIZE(varList), NumberOfGrids), stat=err)
!                IF (err /= 0) PRINT *, ": Allocation request denied"
!             ENDIF
!             dataOutX_agg(:, :, iGrid) = dataOutX_agg0
!          END DO
!       ELSE
!          IF (.NOT. ALLOCATED(dataOutX_agg)) THEN
!             ALLOCATE (dataOutX_agg(SIZE(dataOutX, dim=1), SIZE(varList), NumberOfGrids), stat=err)
!             IF (err /= 0) PRINT *, ": Allocation request denied"
!          ENDIF
!          dataOutX_agg = dataOutX
!       ENDIF

!       ! write out data
!       CALL SUEWS_Write_nc(dataOutX_agg, varList, outLevel)
!       IF (ALLOCATED(dataOutX_agg)) THEN
!          DEALLOCATE (dataOutX_agg)
!          IF (err /= 0) PRINT *, "dataOutX_agg: Deallocation request denied"
!       ENDIF
!    END SUBROUTINE SUEWS_Output_nc_grp

!    ! SUBROUTINE SUEWS_Write_nc(dataOutX, varList, outLevel)
!    !    ! generic subroutine to write out data in netCDF format
!    !    USE netCDF

!    !    IMPLICIT NONE
!    !    REAL(KIND(1d0)), DIMENSION(:, :, :), INTENT(in)::dataOutX
!    !    TYPE(varAttr), DIMENSION(:), INTENT(in)::varList
!    !    INTEGER, INTENT(in) :: outLevel

!    !    CHARACTER(len=365):: fileOut
!    !    REAL(KIND(1d0)), DIMENSION(:, :, :), ALLOCATABLE::dataOutSel
!    !    TYPE(varAttr), DIMENSION(:), ALLOCATABLE::varListSel

!    !    ! We are writing 3D data, {time, y, x}
!    !    INTEGER, PARAMETER :: NDIMS = 3, iVarStart = 6
!    !    INTEGER :: NX, NY, nTime, nVar, err

!    !    ! When we create netCDF files, variables and dimensions, we get back
!    !    ! an ID for each one.
!    !    INTEGER :: ncID, varID, dimids(NDIMS), varIDGrid
!    !    INTEGER :: x_dimid, y_dimid, time_dimid, iVar, varIDx, varIDy, varIDt, varIDCRS
!    !    REAL(KIND(1d0)), ALLOCATABLE :: varOut(:, :, :), &
!    !                                    varX(:, :), varY(:, :), &
!    !                                    lat(:, :), lon(:, :), &
!    !                                    varSeq0(:), varSeq(:), &
!    !                                    xTime(:), xGridID(:, :)

!    !    INTEGER :: idVar(iVarStart:SIZE(varList))
!    !    CHARACTER(len=50):: header_str, longNm_str, unit_str
!    !    CHARACTER(len=4)  :: yrStr2
!    !    CHARACTER(len=40) :: startStr2
!    !    REAL(KIND(1d0)) :: minLat, maxLat, dLat, minLon, maxLon, dLon
!    !    REAL(KIND(1d0)), DIMENSION(1:6) :: geoTrans
!    !    CHARACTER(len=80) :: strGeoTrans

!    !    ! determine number of times
!    !    nTime = SIZE(dataOutX, dim=1)

!    !    !select variables to output
!    !    nVar = COUNT((varList%level <= outLevel), dim=1)
!    !    ALLOCATE (varListSel(nVar), stat=err)
!    !    IF (err /= 0) PRINT *, "varListSel: Allocation request denied"
!    !    varListSel = PACK(varList, mask=(varList%level <= outLevel))

!    !    ! copy data accordingly
!    !    ALLOCATE (dataOutSel(nTime, nVar, NumberOfGrids), stat=err)
!    !    IF (err /= 0) PRINT *, "dataOutSel: Allocation request denied"
!    !    dataOutSel = dataOutX(:, PACK((/(i, i=1, SIZE(varList))/), varList%level <= outLevel), :)

!    !    ! determine filename
!    !    CALL filename_gen(dataOutSel(:, :, 1), varListSel, 1, FileOut)
!    !    ! PRINT*, 'writing file:',TRIM(fileOut)

!    !    ! set year string
!    !    WRITE (yrStr2, '(i4)') INT(dataOutX(1, 1, 1))
!    !    ! get start for later time unit creation
!    !    startStr2 = TRIM(yrStr2)//'-01-01 00:00:00'

!    !    ! define the dimension of spatial array/frame in the output
!    !    nX = nCol
!    !    nY = nRow

!    !    ALLOCATE (varSeq0(nX*nY))
!    !    ALLOCATE (varSeq(nX*nY))
!    !    ALLOCATE (xGridID(nX, nY))
!    !    ALLOCATE (lon(nX, nY))
!    !    ALLOCATE (lat(nX, nY))
!    !    ALLOCATE (varY(nX, nY))
!    !    ALLOCATE (varX(nX, nY))
!    !    ALLOCATE (xTime(nTime))

!    !    ! GridID:
!    !    varSeq = SurfaceChar(1:nX*nY, 1)
!    !    ! CALL sortSeqReal(varSeq0,varSeq,nY,nX)
!    !    xGridID = RESHAPE(varSeq, (/nX, nY/), order=(/1, 2/))
!    !    ! PRINT*, 'before flipping:',lat(1:2,1)
!    !    xGridID = xGridID(:, nY:1:-1)

!    !    ! latitude:
!    !    varSeq = SurfaceChar(1:nX*nY, 5)
!    !    ! CALL sortSeqReal(varSeq0,varSeq,nY,nX)
!    !    lat = RESHAPE(varSeq, (/nX, nY/), order=(/1, 2/))
!    !    ! PRINT*, 'before flipping:',lat(1:2,1)
!    !    lat = lat(:, nY:1:-1)
!    !    ! PRINT*, 'after flipping:',lat(1:2,1)

!    !    ! longitude:
!    !    varSeq = SurfaceChar(1:nX*nY, 6)
!    !    ! CALL sortSeqReal(varSeq0,varSeq,nY,nX)
!    !    lon = RESHAPE(varSeq, (/nX, nY/), order=(/1, 2/))
!    !    lon = lon(:, nY:1:-1)

!    !    ! pass values to coordinate variables
!    !    varY = lat
!    !    varX = lon

!    !    ! calculate GeoTransform array as needed by GDAL
!    !    ! ref: http://www.perrygeo.com/python-affine-transforms.html
!    !    ! the values below are different from the above ref,
!    !    ! as the layout of SUEWS output is different from the schematic shown there
!    !    ! SUEWS output is arranged northward down the page
!    !    ! if data are formatted as a normal matrix
!    !    minLat = lat(1, 1)               ! the lower-left pixel
!    !    maxLat = lat(1, NY)              ! the upper-left pixel
!    !    IF (nY > 1) THEN
!    !       dLat = (maxLat - minLat)/(nY - 1) ! height of a pixel
!    !    ELSE
!    !       dLat = 1
!    !    END IF

!    !    ! PRINT*, 'lat:',minLat,maxLat,dLat
!    !    minLon = lon(1, 1)              ! the lower-left pixel
!    !    maxLon = lon(NX, 1)             ! the lower-right pixel
!    !    IF (nY > 1) THEN
!    !       dLon = (maxLon - minLon)/(nX - 1) ! width of a pixel
!    !    ELSE
!    !       dLon = 1
!    !    END IF

!    !    ! PRINT*, 'lon:',minLon,maxLon,dLon
!    !    geoTrans(1) = minLon - dLon/2          ! x-coordinate of the lower-left corner of the lower-left pixel
!    !    geoTrans(2) = dLon                   ! width of a pixel
!    !    geoTrans(3) = 0.                     ! row rotation (typically zero)
!    !    geoTrans(4) = minLat - dLat/2          ! y-coordinate of the of the lower-left corner of the lower-left pixel
!    !    geoTrans(5) = 0.                     ! column rotation (typically zero)
!    !    geoTrans(6) = dLat                   ! height of a pixel (typically negative, but here positive)
!    !    ! write GeoTransform to strGeoTrans
!    !    WRITE (strGeoTrans, '(6(f12.8,1x))') geoTrans

!    !    ! Create the netCDF file. The nf90_clobber parameter tells netCDF to
!    !    ! overwrite this file, if it already exists.
!    !    CALL check(nf90_create(TRIM(fileOut), NF90_CLOBBER, ncID))

!    !    ! put global attributes
!    !    CALL check(nf90_put_att(ncID, NF90_GLOBAL, 'Conventions', 'CF1.6'))
!    !    CALL check(nf90_put_att(ncID, NF90_GLOBAL, 'title', 'SUEWS output'))
!    !    CALL check(nf90_put_att(ncID, NF90_GLOBAL, 'source', 'Micromet Group, University of Reading'))
!    !    CALL check(nf90_put_att(ncID, NF90_GLOBAL, 'references', 'http://urban-climate.net/umep/SUEWS'))

!    !    ! Define the dimensions. NetCDF will hand back an ID for each.
!    !    ! nY = ncolumnsDataOutSUEWS-4
!    !    ! nx = NumberOfGrids
!    !    CALL check(nf90_def_dim(ncID, "time", NF90_UNLIMITED, time_dimid))
!    !    CALL check(nf90_def_dim(ncID, "west_east", NX, x_dimid))
!    !    CALL check(nf90_def_dim(ncID, "south_north", NY, y_dimid))
!    !    ! PRINT*, 'good define dim'

!    !    ! The dimids array is used to pass the IDs of the dimensions of
!    !    ! the variables. Note that in fortran arrays are stored in
!    !    ! column-major format.
!    !    dimids = (/x_dimid, y_dimid, time_dimid/)

!    !    ! write out each variable
!    !    ALLOCATE (varOut(nX, nY, nTime))

!    !    ! define all variables
!    !    ! define time variable:
!    !    CALL check(nf90_def_var(ncID, 'time', NF90_REAL, time_dimid, varIDt))
!    !    CALL check(nf90_put_att(ncID, varIDt, 'units', 'minutes since '//startStr2))
!    !    CALL check(nf90_put_att(ncID, varIDt, 'long_name', 'time'))
!    !    CALL check(nf90_put_att(ncID, varIDt, 'standard_name', 'time'))
!    !    CALL check(nf90_put_att(ncID, varIDt, 'calendar', 'gregorian'))
!    !    CALL check(nf90_put_att(ncID, varIDt, 'axis', 'T'))

!    !    ! define coordinate variables:
!    !    CALL check(nf90_def_var(ncID, 'lon', NF90_REAL, (/x_dimid, y_dimid/), varIDx))
!    !    CALL check(nf90_put_att(ncID, varIDx, 'units', 'degree_east'))
!    !    CALL check(nf90_put_att(ncID, varIDx, 'long_name', 'longitude'))
!    !    CALL check(nf90_put_att(ncID, varIDx, 'standard_name', 'longitude'))
!    !    CALL check(nf90_put_att(ncID, varIDx, 'axis', 'X'))

!    !    CALL check(nf90_def_var(ncID, 'lat', NF90_REAL, (/x_dimid, y_dimid/), varIDy))
!    !    CALL check(nf90_put_att(ncID, varIDy, 'units', 'degree_north'))
!    !    CALL check(nf90_put_att(ncID, varIDy, 'long_name', 'latitude'))
!    !    CALL check(nf90_put_att(ncID, varIDy, 'standard_name', 'latitude'))
!    !    CALL check(nf90_put_att(ncID, varIDy, 'axis', 'Y'))

!    !    ! define coordinate referencing system:
!    !    CALL check(nf90_def_var(ncID, 'crsWGS84', NF90_INT, varIDCRS))
!    !    CALL check(nf90_put_att(ncID, varIDCRS, 'grid_mapping_name', 'latitude_longitude'))
!    !    CALL check(nf90_put_att(ncID, varIDCRS, 'long_name', 'CRS definition'))
!    !    CALL check(nf90_put_att(ncID, varIDCRS, 'longitude_of_prime_meridian', '0.0'))
!    !    CALL check(nf90_put_att(ncID, varIDCRS, 'semi_major_axis', '6378137.0'))
!    !    CALL check(nf90_put_att(ncID, varIDCRS, 'inverse_flattening', '298.257223563'))
!    !    CALL check(nf90_put_att(ncID, varIDCRS, 'epsg_code', 'EPSG:4326'))
!    !    CALL check(nf90_put_att(ncID, varIDCRS, 'GeoTransform', TRIM(strGeoTrans)))
!    !    CALL check(nf90_put_att(ncID, varIDCRS, 'spatial_ref',&
!    !         &'GEOGCS["WGS 84",&
!    !         &    DATUM["WGS_1984",&
!    !         &        SPHEROID["WGS 84",6378137,298.257223563,&
!    !         &            AUTHORITY["EPSG","7030"]],&
!    !         &        AUTHORITY["EPSG","6326"]],&
!    !         &    PRIMEM["Greenwich",0],&
!    !         &    UNIT["degree",0.0174532925199433],&
!    !         &    AUTHORITY["EPSG","4326"]]' &
!    !         ))

!    !    ! define grid_ID:
!    !    CALL check(nf90_def_var(ncID, 'grid_ID', NF90_INT, (/x_dimid, y_dimid/), varIDGrid))
!    !    CALL check(nf90_put_att(ncID, varIDGrid, 'coordinates', 'lon lat'))
!    !    CALL check(nf90_put_att(ncID, varIDGrid, 'long_name', 'Grid ID as in SiteSelect'))
!    !    CALL check(nf90_put_att(ncID, varIDGrid, 'grid_mapping', 'crsWGS84'))
!    !    ! varIDGrid=varID

!    !    ! define other 3D variables:
!    !    DO iVar = iVarStart, nVar
!    !       ! define variable name
!    !       header_str = varListSel(iVar)%header
!    !       unit_str = varListSel(iVar)%unit
!    !       longNm_str = varListSel(iVar)%longNm

!    !       ! Define the variable. The type of the variable in this case is
!    !       ! NF90_REAL.

!    !       CALL check(nf90_def_var(ncID, TRIM(ADJUSTL(header_str)), NF90_REAL, dimids, varID))

!    !       CALL check(nf90_put_att(ncID, varID, 'coordinates', 'lon lat'))

!    !       CALL check(nf90_put_att(ncID, varID, 'units', TRIM(ADJUSTL(unit_str))))

!    !       CALL check(nf90_put_att(ncID, varID, 'long_name', TRIM(ADJUSTL(longNm_str))))

!    !       CALL check(nf90_put_att(ncID, varID, 'grid_mapping', 'crsWGS84'))

!    !       idVar(iVar) = varID
!    !    END DO
!    !    CALL check(nf90_enddef(ncID))
!    !    ! End define mode. This tells netCDF we are done defining metadata.

!    !    ! put all variable values into netCDF datasets
!    !    ! put time variable in minute:
!    !    xTime = (dataOutSel(1:nTime, 2, 1) - 1)*24*60 + dataOutSel(1:nTime, 3, 1)*60 + dataOutSel(1:nTime, 4, 1)
!    !    CALL check(nf90_put_var(ncID, varIDt, xTime))

!    !    ! put coordinate variables:
!    !    CALL check(nf90_put_var(ncID, varIDx, varX))
!    !    CALL check(nf90_put_var(ncID, varIDy, varY))

!    !    ! put CRS variable:
!    !    CALL check(nf90_put_var(ncID, varIDCRS, 9999))

!    !    CALL check(NF90_SYNC(ncID))
!    !    ! PRINT*, 'good put var'

!    !    ! put grid_ID:
!    !    CALL check(nf90_put_var(ncID, varIDGrid, xGridID))
!    !    ! PRINT*, 'good put varIDGrid',varIDGrid

!    !    CALL check(NF90_SYNC(ncID))

!    !    ! then other 3D variables
!    !    DO iVar = iVarStart, nVar
!    !       ! reshape dataOutX to be aligned in checker board form
!    !       varOut = RESHAPE(dataOutSel(1:nTime, iVar, :), (/nX, nY, nTime/), order=(/3, 1, 2/))
!    !       varOut = varOut(:, nY:1:-1, :)
!    !       !  get the variable id
!    !       varID = idVar(iVar)

!    !       CALL check(nf90_put_var(ncID, varID, varOut))

!    !       CALL check(NF90_SYNC(ncID))
!    !    END DO

!    !    IF (ALLOCATED(varOut)) DEALLOCATE (varOut)
!    !    IF (ALLOCATED(varSeq0)) DEALLOCATE (varSeq0)
!    !    IF (ALLOCATED(varSeq)) DEALLOCATE (varSeq)
!    !    IF (ALLOCATED(xGridID)) DEALLOCATE (xGridID)
!    !    IF (ALLOCATED(lon)) DEALLOCATE (lon)
!    !    IF (ALLOCATED(lat)) DEALLOCATE (lat)
!    !    IF (ALLOCATED(varY)) DEALLOCATE (varY)
!    !    IF (ALLOCATED(varX)) DEALLOCATE (varX)
!    !    IF (ALLOCATED(xTime)) DEALLOCATE (xTime)

!    !    ! Close the file. This frees up any internal netCDF resources
!    !    ! associated with the file, and flushes any buffers.
!    !    CALL check(nf90_close(ncID))

!    !    ! PRINT*, "*** SUCCESS writing netCDF file:"
!    !    ! PRINT*, FileOut
!    ! END SUBROUTINE SUEWS_Write_nc

!    !===========================================================================!
!    ! convert a vector of grids to a matrix
!    ! the grid IDs in seqGrid2Sort follow the QGIS convention
!    ! the spatial matrix arranges successive rows down the page (i.e., north to south)
!    !   and succesive columns across (i.e., west to east)
!    ! seqGridSorted stores the grid IDs as aligned in matGrid but squeezed into a vector
!    !===========================================================================!
!    SUBROUTINE grid2mat(seqGrid2Sort, seqGridSorted, matGrid, nRow, nCol)

!       IMPLICIT NONE

!       INTEGER, DIMENSION(nRow*nCol) :: seqGrid2Sort, seqGridSorted
!       INTEGER, DIMENSION(nRow, nCol) :: matGrid
!       INTEGER :: nRow, nCol, i, j, loc

!       CALL sortGrid(seqGrid2Sort, seqGridSorted, nRow, nCol)
!       PRINT *, 'old:'
!       PRINT *, seqGrid2Sort(1:5)
!       PRINT *, 'sorted:'
!       PRINT *, seqGridSorted(1:5)
!       PRINT *, ''
!       DO i = 1, nRow
!          DO j = 1, nCol
!             loc = (i - 1)*nCol + j
!             matGrid(i, j) = seqGridSorted(loc)
!          END DO
!       END DO
!    END SUBROUTINE grid2mat

!    !===========================================================================!
!    ! convert sequence of REAL values to a matrix
!    ! the grid IDs in seqGrid2Sort follow the QGIS convention
!    ! the spatial matrix arranges successive rows down the page (i.e., north to south)
!    !   and succesive columns across (i.e., west to east)
!    ! seqGridSorted stores the grid IDs as aligned in matGrid but squeezed into a vector
!    !===========================================================================!
!    SUBROUTINE seq2mat(seq2Sort, seqSorted, matGrid, nRow, nCol)

!       IMPLICIT NONE

!       REAL(KIND(1d0)), DIMENSION(nRow*nCol) :: seq2Sort, seqSorted
!       REAL(KIND(1d0)), DIMENSION(nRow, nCol) :: matGrid
!       INTEGER :: nRow, nCol, i, j, loc

!       CALL sortSeqReal(seq2Sort, seqSorted, nRow, nCol)
!       PRINT *, 'old:'
!       PRINT *, seq2Sort(1:5)
!       PRINT *, 'sorted:'
!       PRINT *, seqSorted(1:5)
!       PRINT *, ''
!       DO i = 1, nRow
!          DO j = 1, nCol
!             loc = (i - 1)*nCol + j
!             matGrid(i, j) = seqSorted(loc)
!          END DO
!       END DO
!    END SUBROUTINE seq2mat

!    !===========================================================================!
!    ! sort a sequence of LONG values into the specially aligned sequence per QGIS
!    !===========================================================================!
!    SUBROUTINE sortGrid(seqGrid2Sort0, seqGridSorted, nRow, nCol)
!       USE qsort_c_module
!       ! convert a vector of grids to a matrix
!       ! the grid IDs in seqGrid2Sort follow the QGIS convention
!       ! the spatial matrix arranges successive rows down the page (i.e., north to south)
!       !   and succesive columns across (i.e., west to east)
!       ! seqGridSorted stores the grid IDs as aligned in matGrid but squeezed into a vector

!       IMPLICIT NONE
!       INTEGER :: nRow, nCol, i = 1, j = 1, xInd, len

!       INTEGER, DIMENSION(nRow*nCol), INTENT(in) :: seqGrid2Sort0
!       INTEGER, DIMENSION(nRow*nCol), INTENT(out) :: seqGridSorted
!       INTEGER, DIMENSION(nRow*nCol) :: seqGrid2Sort, locSorted
!       INTEGER :: loc
!       REAL:: ind(nRow*nCol, 2)
!       REAL, DIMENSION(nRow*nCol) :: seqGrid2SortReal, seqGridSortedReal
!       REAL :: val

!       ! number of grids
!       len = nRow*nCol

!       !sort the input array to make sure the grid order is in QGIS convention
!       ! i.e., diagonally ascending
!       seqGrid2SortReal = seqGrid2Sort0*1.
!       CALL QsortC(seqGrid2SortReal)
!       seqGrid2Sort = INT(seqGrid2SortReal)

!       ! fill in an nRow*nCol array with values to determine sequence
!       xInd = 1
!       DO i = 1, nRow
!          DO j = 1, nCol
!             !  {row, col, value for sorting, index in new sequence}
!             ind(xInd, :) = (/i + j + i/(nRow + 1.), xInd*1./)
!             xInd = xInd + 1
!          END DO
!       END DO

!       ! then sorted ind(:,3) will have the same order as seqGrid2Sort
!       ! sort ind(:,3)
!       seqGridSortedReal = ind(:, 1)*1.
!       CALL QsortC(seqGridSortedReal)
!       ! print*, 'sorted real:'
!       ! print*, seqGridSortedReal

!       ! get index of each element of old sequence in the sorted sequence
!       DO i = 1, len
!          ! value in old sequence
!          !  val=ind(i,3)*1.
!          val = seqGridSortedReal(i)
!          DO j = 1, len
!             IF (val == ind(j, 1)*1.) THEN
!                ! location in sorted sequence
!                locSorted(i) = j
!             END IF
!          END DO
!       END DO

!       ! put elements of old sequence in the sorted order
!       DO i = 1, len
!          loc = locSorted(i)
!          seqGridSorted(loc) = seqGrid2Sort(i)
!       END DO
!       seqGridSorted = seqGridSorted(len:1:-1)

!    END SUBROUTINE sortGrid

!    !===========================================================================!
!    ! sort a sequence of REAL values into the specially aligned sequence per QGIS
!    !===========================================================================!
!    SUBROUTINE sortSeqReal(seqReal2Sort, seqRealSorted, nRow, nCol)
!       USE qsort_c_module
!       ! convert a vector of grids to a matrix
!       ! the grid IDs in seqReal2Sort follow the QGIS convention
!       ! the spatial matrix arranges successive rows down the page (i.e., north to south)
!       !   and succesive columns across (i.e., west to east)
!       ! seqRealSorted stores the grid IDs as aligned in matGrid but squeezed into a vector

!       IMPLICIT NONE
!       INTEGER :: nRow, nCol, i = 1, j = 1, xInd, len

!       REAL(KIND(1d0)), DIMENSION(nRow*nCol), INTENT(in) :: seqReal2Sort
!       REAL(KIND(1d0)), DIMENSION(nRow*nCol), INTENT(out) :: seqRealSorted
!       INTEGER(KIND(1d0)), DIMENSION(nRow*nCol) :: locSorted
!       INTEGER(KIND(1d0)) :: loc
!       REAL:: ind(nRow*nCol, 2)
!       REAL :: seqRealSortedReal(nRow*nCol), val

!       ! number of grids
!       len = nRow*nCol

!       ! fill in an nRow*nCol array with values to determine sequence
!       xInd = 1
!       DO i = 1, nRow
!          DO j = 1, nCol
!             !  {row, col, value for sorting, index in new sequence}
!             ind(xInd, :) = (/i + j + i/(nRow + 1.), xInd*1./)
!             xInd = xInd + 1
!          END DO
!       END DO

!       ! then sorted ind(:,3) will have the same order as seqReal2Sort
!       ! sort ind(:,3)
!       seqRealSortedReal = ind(:, 1)*1.
!       CALL QsortC(seqRealSortedReal)
!       ! print*, 'sorted real:'
!       ! print*, seqRealSortedReal

!       ! get index of each element of old sequence in the sorted sequence
!       DO i = 1, len
!          ! value in old sequence
!          !  val=ind(i,3)*1.
!          val = seqRealSortedReal(i)
!          DO j = 1, len
!             IF (val == ind(j, 1)*1.) THEN
!                ! location in sorted sequence
!                locSorted(i) = j
!             END IF
!          END DO
!       END DO

!       ! put elements of old sequence in the sorted order
!       DO i = 1, len
!          loc = locSorted(i)
!          seqRealSorted(loc) = seqReal2Sort(i)
!       END DO
!       seqRealSorted = seqRealSorted(len:1:-1)

!    END SUBROUTINE sortSeqReal

!    !===========================================================================!
!    ! a wrapper for checking netCDF status
!    !===========================================================================!

!    SUBROUTINE check(status)
!       USE netcdf
!       IMPLICIT NONE

!       INTEGER, INTENT(in) :: status

!       IF (status /= nf90_noerr) THEN
!          PRINT *, TRIM(nf90_strerror(status))
!          STOP "Stopped"
!       END IF
!    END SUBROUTINE check
! #endif

END MODULE ctrl_output
