set( BasicModules
PhysParamModule.F90 ChemElementModule.F90 PublicTypeDefinitionsModule.F90
PublicParamDefinitionsModule.F90 AdaptIntegrationModule.F90
MatrixBlockInversionModule.F90 BinvMatrix.F90 WriteFunctionModule.F90
DefaultParamModule.F90 LatticeModule.F90 IBZRotationModule.F90
CheckPointModule.F90
)

set( BasicRoutines
readPositionData.F90 readMomentDirectionData.F90 readInputInOtherFormat.F90
readOldInfoTable.F90 rdin_old_lsms.F90 rdin_old_infotable.F90
rdin_old_infoevec.F90 getValueAtPosi.F90 lattice.F90 averageAcrossProcesses.F90
setupSemiCircleContour.F90 getFermiDiracFunc.F90
)

set( AppModules
InputModule.F90 ScfDataModule.F90 PotentialTypeModule.F90
ExchCorrFunctionalModule.F90 SystemModule.F90 BZoneModule.F90
MatsubaraModule.F90 ContourModule.F90 ProcMappingModule.F90 Atom2ProcModule.F90
PolyhedraModule.F90 SystemVolumeModule.F90 OutputModule.F90 VPI_main.f
IsoparametricIntegrationModule.F90 NeighborModule.F90 SendRecvTmatModule.F90
AtomModule.F90 StepFunctionModule.F90 MadelungModule.F90
SystemSymmetryModule.F90 LdaCorrectionModule.F90 RadialGridModule.F90
PotentialModule.F90 StrConstModule.F90 RSpaceStrConstModule.F90
TriangleModule.F90 PolygonModule.F90 SurfElementsModule.F90
SpinRotationModule.F90 SSSolverModule.F90 DiracSolverModule.F90
RelScattererModule.F90 RelSSSolverModule.F90 SingleScatteringDOSModule.F90
SCPolesModule.F90 SMatrixPolesModule.F90 SineMatrixZerosModule.F90
KreinModule.F90 CoreStatesModule.F90 Uniform3DGridModule.F90
ParallelFFTModule.F90 ConstrainLocalMomentModule.F90 ValenceDensityModule.F90
ChargeDensityModule.F90 ChargeDistributionModule.F90 ChargeScreeningModule.F90
PotentialGenerationModule.F90 TotalEnergyModule.F90 ConvergenceCheckModule.F90
MixingModule.F90 TestPotentialModule.F90 BookKeepingModule.F90 ForceModule.F90
)

set( HDF5Module
HDF5Module.F90
)

set( Modules_2
ClusterMatrixModule.F90 MediumHostModule.F90 SROModule.F90
CrystalMatrixModule.F90 AccelerateCPAModule.F90 EmbeddedClusterModule.F90
CPAMediumModule.F90 BandStructureModule.F90 MSSolverModule.F90
RelMSSolverModule.F90 MultiScatteringDOSModule.F90 RelGreenFunctionModule.F90
GFMethodModule.F90
)

set( Routines
setupLizNeighbor.F90 buildSendTable.F90 constructDataOnGrid.F90
printDataOnGrid.F90 printDataOnLine.F90 updatePotential.F90
setupMixingScheme.F90 setupMixRealArrayList.F90 setupMixCmplxArrayList.F90
updateMixRealValues.F90 updateMixCmplxValues.F90 potredg.F90 getpotg.F90
putpotg.F90 keep.F90 averageDOS.F90 printSystemMovie.F90 print_version.F90
driverSystemMovie.F90 force_openmp.F90 print_threads.F90 convertGijToRel.F90
gaspari_gyorffy_formula.F90 printMomentVsCoreSplit.F90 polyfermi.F90
calNicholsonPoles.F90 fetchVisualDomainParameters.F90 printDensityOnGrid.F90
printPotentialOnGrid.F90 printScfResults.F90 adjustEnergy.F90
)
