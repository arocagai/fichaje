# Fichaje

Primera base de una app Flutter para registrar entradas y salidas desde móvil y escritorio.

## Plataformas

Flutter permite compilar esta app para Android, iOS, Windows, Linux y macOS. Para generar los proyectos nativos y ejecutar la aplicación hace falta instalar el SDK de Flutter y habilitar los destinos de escritorio en el equipo de desarrollo. Este entorno no tiene Flutter instalado, así que aquí se ha preparado el código Dart inicial, pero todavía no se ha podido generar ni ejecutar la app.

## Estado actual

- Pantalla de jornada con tiempo trabajado, tiempo restante y progreso.
- Secuencia de entrada, salida a mediodía, entrada por la tarde y salida final.
- Entrada manual de una hora con selector horario.
- Jornada inicial de 8 horas y pausa mínima de 30 minutos.

Los registros y la configuración aún viven solo en memoria y se pierden al cerrar la app. El siguiente paso es guardar localmente y conectar una base de datos central para sincronizar los dispositivos.

## Backend previsto

La opción propuesta es Supabase: PostgreSQL, login con Google mediante Supabase Auth y acceso a datos con políticas Row Level Security (RLS). Esto permite mantener los registros privados por usuario y evita tener que desarrollar una API propia para las operaciones habituales. Supabase también ofrece SDK Flutter para web, iOS, Android, macOS y Windows. Para Linux se puede valorar la versión web o comprobar el soporte de la librería que elijamos.

Se pueden usar dos proyectos Supabase, uno de desarrollo y otro de producción. El plan gratuito permite dos proyectos activos, cada uno con su propia base PostgreSQL y límites independientes. Aún no hay proyectos ni credenciales configurados.

La app todavía no persiste los fichajes ni se conecta al backend. Antes de publicar datos reales habrá que crear los proyectos, configurar Google OAuth, definir el esquema y activar políticas RLS para que cada usuario solo pueda consultar y modificar sus fichajes.
