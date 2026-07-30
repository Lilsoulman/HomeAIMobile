// WMO weather code → emoji + 中文描述
// 来源：Open-Meteo 官方代码表
const MAP = {
  0: { icon: '☀️', desc: { zh: '晴', en: 'Clear' } },
  1: { icon: '🌤️', desc: { zh: '少云', en: 'Mainly clear' } },
  2: { icon: '⛅', desc: { zh: '多云', en: 'Partly cloudy' } },
  3: { icon: '☁️', desc: { zh: '阴', en: 'Overcast' } },
  45: { icon: '🌫️', desc: { zh: '雾', en: 'Fog' } },
  48: { icon: '🌫️', desc: { zh: '雾凇', en: 'Rime fog' } },
  51: { icon: '🌦️', desc: { zh: '小毛毛雨', en: 'Drizzle' } },
  53: { icon: '🌦️', desc: { zh: '毛毛雨', en: 'Drizzle' } },
  55: { icon: '🌧️', desc: { zh: '强毛毛雨', en: 'Heavy drizzle' } },
  61: { icon: '🌧️', desc: { zh: '小雨', en: 'Light rain' } },
  63: { icon: '🌧️', desc: { zh: '中雨', en: 'Rain' } },
  65: { icon: '🌧️', desc: { zh: '大雨', en: 'Heavy rain' } },
  71: { icon: '🌨️', desc: { zh: '小雪', en: 'Light snow' } },
  73: { icon: '🌨️', desc: { zh: '中雪', en: 'Snow' } },
  75: { icon: '❄️', desc: { zh: '大雪', en: 'Heavy snow' } },
  77: { icon: '🌨️', desc: { zh: '雪粒', en: 'Snow grains' } },
  80: { icon: '🌦️', desc: { zh: '阵雨', en: 'Showers' } },
  81: { icon: '🌧️', desc: { zh: '强阵雨', en: 'Heavy showers' } },
  82: { icon: '⛈️', desc: { zh: '暴阵雨', en: 'Violent showers' } },
  85: { icon: '🌨️', desc: { zh: '阵雪', en: 'Snow showers' } },
  86: { icon: '❄️', desc: { zh: '强阵雪', en: 'Heavy snow showers' } },
  95: { icon: '⛈️', desc: { zh: '雷暴', en: 'Thunderstorm' } },
  96: { icon: '⛈️', desc: { zh: '雷暴冰雹', en: 'Thunderstorm w/ hail' } },
  99: { icon: '⛈️', desc: { zh: '强雷暴冰雹', en: 'Severe thunderstorm' } }
}

export function getWeatherIcon (code) {
  return (MAP[code] || MAP[0]).icon
}
export function getWeatherDesc (code, lang = 'zh') {
  return (MAP[code] || MAP[0]).desc[lang] || (MAP[code] || MAP[0]).desc.zh
}
