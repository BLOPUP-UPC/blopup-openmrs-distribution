function getEvolution(first, last) {
  if (first == last) return "IGUAL"
  if (first > last) return "MEJORADO"
  if (first < last) return "EMPEORADO"
}

function getBloodPressureStage(systolic, diastolic) {
  const value = getBloodPressureValue(systolic, diastolic)

  switch (value) {
    case 5:
      return "NIVEL II C"
    case 4:
      return "NIVEL II B"
    case 3:
      return "NIVEL II A"
    case 2:
      return "NIVEL I"
    default:
      return "NORMAL"
  }
}

function getBloodPressureValue(systolic, diastolic) {
  if(systolic >= 180 || diastolic >= 110) {
    return 5
  } else if(systolic >= 160 || diastolic >= 100){
    return 4
  } else if(systolic >= 140 || diastolic >= 90){
    return 3
  } else if(systolic >= 130 || diastolic >= 80){
    return 2
  } else {
    return 1
  }
}