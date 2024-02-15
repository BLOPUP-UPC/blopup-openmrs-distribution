function fetchReport(id, inputUser = null, inputPwd = null, host = "blopup.upc.edu") {
  const user = inputUser ?? PropertiesService.getScriptProperties().getProperty("openmrs_username")
  const pwd = inputPwd ?? PropertiesService.getScriptProperties().getProperty("openmrs_password")
  const url = `https://${host}/openmrs/ws/rest/v1/reportingrest/dataSet/${id}`
  const options = {
    method: 'GET', 
    headers: {
      'Content-Type': 'application/json',
      'Authorization': "Basic " + Utilities.base64Encode(user + ":" + pwd)
      }
  }
  const response = JSON.parse(UrlFetchApp.fetch(url, options).getContentText())

  console.log(`${response.rows.length} rows found.`)
  return response.rows
}

function fetchDevReport(id) {
  return fetchReport(id, PropertiesService.getScriptProperties().getProperty("dev_username"), PropertiesService.getScriptProperties().getProperty("dev_password"), 'blopup-dev.upc.edu')
}

function fillData(sheetName, rows, columnNames, buildRowFunction) {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName)
  sheet.clearContents()

  sheet.appendRow(columnNames)

  const range = sheet.getRange(2, 1, rows.length, columnNames.length)
  range.setValues(
    rows.map((row, index) => buildRowFunction(row, index))
  )

  console.log("Done!")
}