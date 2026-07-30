// 天气 mock：直接返回示例数据。真实接入时改为调 Open-Meteo
const sample = {
  city: '北京市',
  lat: 39.9042,
  lon: 116.4074,
  current: {
    temperature_2m: 28,
    apparent_temperature: 30,
    relative_humidity_2m: 56,
    weather_code: 2,
    wind_speed_10m: 8
  },
  daily: {
    time: [],
    weather_code: [2, 2, 3, 61, 61, 3, 2, 2],
    temperature_2m_max: [29, 30, 27, 25, 26, 28, 29, 30],
    temperature_2m_min: [20, 21, 20, 19, 18, 19, 20, 21]
  }
}
const base = new Date()
base.setHours(0, 0, 0, 0)
for (let i = 0; i < 8; i++) {
  const d = new Date(base)
  d.setDate(d.getDate() + i)
  sample.daily.time.push(d.toISOString().slice(0, 10))
}

export const mockWeather = {
  get () { return { code: 0, data: sample } }
}
