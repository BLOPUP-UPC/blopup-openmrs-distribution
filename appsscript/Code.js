function triggerAll() {
  runListOfRegisteredPatientsReport()
  runLatestBloodPressureValuesReport()
  runFirstAndLastBloodPressureValuesReport()
  runAverageVisitPerPatientsReport()
  runVitalsTakenPerDay()
}

function runListOfRegisteredPatientsReport() {
  console.log("Procesing fetchListOfRegisteredPatients")
  const rows = fetchReport("f7466499-7798-475d-96a0-834650a94840")

  fillData(
    'Datos - Registro de pacientes', 
    rows, 
    ["identificador", "fecha de registro", "uuid"], 
    (row => [row.identifier, Utilities.formatDate(new Date(row.date_created), 'Europe/Madrid', 'MM/dd/yyyy'), row.uuid])
  )
}

function runLatestBloodPressureValuesReport() {
  console.log("Procesing fetchLatestBloodPressureValues")
  const rows = fetchReport("2de744ea-6804-48a4-a68d-217e8109b548")

  const filteredRows = rows.filter(row => row.is_latest == "1")

  console.log(`${filteredRows.length} rows found after filtering. Processing...`)

  fillData(
    'Datos - Presión arterial', 
    filteredRows, 
    ["identificador", "sistólica", "diastólica", "nivel", "fecha", "pais de nacimiento", "continente de nacimiento"], 
    ((row, index) => [
      row.identifier,
      row.systolic,
      row.diastolic,
      getBloodPressureStage(row.systolic, row.diastolic),
      Utilities.formatDate(new Date(row.obs_datetime), 'Europe/Madrid', 'MM/dd/yyyy'),
      row.birthPlace,
      `=LOOKUP(F${index + 2},'Paises y Continentes'!A:B)`
    ])
  )
}

function runFirstAndLastBloodPressureValuesReport() {
  console.log("Processing fetchFirstAndLastBloodPressureValues")
  const rows = fetchReport("2de744ea-6804-48a4-a68d-217e8109b548")
  const patientsActiveTreatments = fetchReport("ab6cca87-e5ba-426b-82bd-e92c5691ce8a").reduce((acc, patient) => ({ ...acc, [patient.identifier]: patient}), {})

 const indexedByPatientId = {}

 rows.forEach(row => {
  const previousRow = indexedByPatientId[row.identifier] ?? []
    indexedByPatientId[row.identifier] = [...previousRow, row].sort((a, b) => a.is_latest - b.is_latest)
  })

  const result = Object.values(indexedByPatientId)

  const filtered = result.filter(item => item.length > 1)
  const patientsEvolution = filtered.map((current) => {
    const lastStage = getBloodPressureValue(current[0].systolic, current[0].diastolic);
    const firstStage = getBloodPressureValue(current[current.length - 1].systolic, current[current.length - 1].diastolic);

    const evolution = getEvolution(firstStage, lastStage);

    return { identifier: current[0].identifier, bpEvolution: evolution };
  });
     
  console.log(`${patientsEvolution.length} rows found after filtering for patients with more than one visit. Processing...`)

  fillData( 'Datos - Evolución de la presión arterial', patientsEvolution,  ["identificador", "evolución", "tratamientos activos"],  row =>   [row.identifier,  row.bpEvolution, patientsActiveTreatments[row.identifier]?.["Tratamientos activos"] ?? 0])
}

function runAverageVisitPerPatientsReport() {
  console.log("Processing averageVisitPerPatientsReport")
  const rows = fetchReport("2de744ea-6804-48a4-a68d-217e8109b548")

  const indexedByPatientId = {}

  rows.forEach(row => {
    const previousRow = indexedByPatientId[row.identifier] ?? []
    indexedByPatientId[row.identifier] = [...previousRow, row]
  })

  const patientsVisitsCount = Object.values(indexedByPatientId).map((current) => {
    return { identifier: current[0].identifier, visitsCount: current.length };
  });
     
  fillData( 'Datos - Media de visitas por paciente', patientsVisitsCount,  ["identificador", "número de visitas"],  row =>   [row.identifier,  row.visitsCount])
}

function runVitalsTakenPerDay() {
  console.log("Procesing runVitalsTakenPerDay")
  const rows = fetchReport("1357085f-f76f-41cd-a47d-d7875a375cd0")

  fillData(
    'Datos - Vitales por dia', 
    rows, 
    ["encounter id", "fecha"], 
    (row => [row.encounter_id, Utilities.formatDate(new Date(row.encounter_datetime), 'Europe/Madrid', 'MM/dd/yyyy')])
  )
}