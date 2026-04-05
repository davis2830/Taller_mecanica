from celery import shared_task
from .models import Cita
from .utils import enviar_email_cita

@shared_task
def enviar_correo_cita_task(cita_id, tipo_email, dominio=None):
    try:
        cita = Cita.objects.get(id=cita_id)
        enviado = enviar_email_cita(cita, tipo_email, dominio=dominio)
        return f"Email {tipo_email} enviado: {enviado} para Cita {cita_id}"
    except Cita.DoesNotExist:
        return f"Error: Cita {cita_id} no existe."
    except Exception as e:
        return f"Error enviando email para cita {cita_id}: {str(e)}"
