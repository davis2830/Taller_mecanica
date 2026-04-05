from celery import shared_task
from .models import Factura
from .utils import enviar_email_factura

@shared_task
def enviar_factura_task(factura_id, destinatario_email=None):
    try:
        factura = Factura.objects.get(id=factura_id)
        enviado = enviar_email_factura(factura, destinatario_email)
        return f"Factura #{factura.numero_factura} enviada a {destinatario_email or 'cliente predeterminado'}: {enviado}"
    except Factura.DoesNotExist:
        return f"Error: Factura {factura_id} no existe."
    except Exception as e:
        return f"Error enviando email para factura {factura_id}: {str(e)}"
