export interface WeatherData {
  heatIndex: number;
  windResistance: number;
}

export async function getWeatherDataForCourse(lat: number, lon: number): Promise<WeatherData> {
  const apiKey = process.env.WEATHER_API_KEY;
  if (!apiKey || apiKey === 'temp_weather_key') {
    return { heatIndex: 85, windResistance: 5 }; // Fallback
  }

  try {
    const response = await fetch(`https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=imperial`);
    if (!response.ok) throw new Error('Weather API error');
    const data = await response.json();
    
    // Very basic heat index approximation using temp
    const tempF = data.main.temp;
    const windMph = data.wind.speed;

    return {
      heatIndex: tempF,
      windResistance: windMph
    };
  } catch (error) {
    console.error('Failed to fetch weather:', error);
    return { heatIndex: 85, windResistance: 5 }; // Fallback on failure
  }
}
