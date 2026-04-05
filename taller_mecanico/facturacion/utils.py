# facturacion/utils.py
from django.core.mail import EmailMultiAlternatives
from django.conf import settings
from citas.utils import formato_fecha_es
import datetime

def enviar_email_factura(factura, destinatario_email=None):
    """
    Construye y envía una factura electrónica robusta en formato HTML y Texto
    a través del correo asociado a la Orden relacionada.
    """
    orden = factura.orden
    cita = orden.cita

    if not destinatario_email:
        if cita and cita.cliente:
            destinatario_email = cita.cliente.email
    
    if not destinatario_email:
        return False
        
    asunto = f'🧾 Factura Electrónica #{factura.numero_factura} - Taller Mecánico'
    titulo = 'Comprobante de Pago'
    fecha_emision = formato_fecha_es(factura.fecha_pagada) if factura.fecha_pagada else formato_fecha_es(datetime.date.today())
    
    # Manejar posibles valores en cero o None
    monto_mo = float(factura.costo_mano_obra)
    monto_rep = float(factura.costo_repuestos)
    monto_dto = float(factura.descuento)
    subtotal = monto_mo + monto_rep
    total = subtotal - monto_dto
    
    cliente_nombre = "Cliente"
    if cita and cita.cliente:
        cliente_nombre = cita.cliente.first_name or cita.cliente.username

    vehiculo_desc = "Vehículo"
    if orden and orden.vehiculo:
        vehiculo_desc = f"{orden.vehiculo.marca} {orden.vehiculo.modelo} ({orden.vehiculo.placa})"

    # Construcción de las filas de los Repuestos consumidos 
    filas_repuestos_html = ""
    filas_repuestos_txt = ""
    for rep in orden.repuestos.all():
        importe_rep = float(rep.cantidad * rep.precio_unitario)
        filas_repuestos_html += f"""
        <tr>
            <td style="padding: 10px 0; border-bottom: 1px dotted #dee2e6; color: #495057;">  {rep.cantidad}x {rep.producto.nombre}</td>
            <td style="padding: 10px 0; border-bottom: 1px dotted #dee2e6; color: #212529; text-align: right;">Q{importe_rep:.2f}</td>
        </tr>
        """
        filas_repuestos_txt += f"  - {rep.cantidad}x {rep.producto.nombre}: Q{importe_rep:.2f}\n"

    # HTML Email con estilo premium enfocado a una factura clara
    mensaje_html = f"""
    <html>
    <body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f4f6f9;">
        <div style="max-width: 600px; margin: 30px auto; background-color: white; border-radius: 12px; overflow: hidden; box-shadow: 0 8px 16px rgba(0,0,0,0.08);">
            
            <!-- Header Comercial -->
            <div style="background: linear-gradient(135deg, #1e293b, #0f172a); color: white; padding: 35px 25px; text-align: center; border-bottom: 5px solid #3b82f6;">
                <h1 style="margin: 0; font-size: 26px; font-weight: 400; letter-spacing: 1px;">
                    🧾 {titulo}
                </h1>
                <p style="margin: 8px 0 0 0; opacity: 0.8; font-size: 15px;">
                    Taller Mecánico Profesional
                </p>
            </div>
            
            <!-- Cuerpo -->
            <div style="padding: 35px;">
                <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 30px;">
                    <div>
                        <p style="margin: 0; font-size: 14px; color: #64748b; font-weight: 600; text-transform: uppercase;">Factura a:</p>
                        <p style="margin: 5px 0 0 0; font-size: 18px; color: #1e293b;"><strong>{cliente_nombre}</strong></p>
                        <p style="margin: 5px 0 0 0; font-size: 14px; color: #475569;">{vehiculo_desc}</p>
                    </div>
                    <div style="text-align: right;">
                        <p style="margin: 0; font-size: 14px; color: #64748b; font-weight: 600; text-transform: uppercase;">Folio:</p>
                        <p style="margin: 5px 0 0 0; font-size: 18px; color: #3b82f6; font-weight: bold;">{factura.numero_factura}</p>
                        <p style="margin: 5px 0 0 0; font-size: 14px; color: #475569;">{fecha_emision}</p>
                    </div>
                </div>
                
                <!-- Desglose Card -->
                <div style="border: 1px solid #e2e8f0; border-radius: 8px; padding: 0; overflow: hidden; margin-bottom: 25px;">
                    <table style="width: 100%; border-collapse: collapse;">
                        <thead style="background-color: #f8fafc;">
                            <tr>
                                <th style="padding: 12px 20px; text-align: left; font-size: 13px; color: #64748b; text-transform: uppercase; font-weight: 600;">Concepto</th>
                                <th style="padding: 12px 20px; text-align: right; font-size: 13px; color: #64748b; text-transform: uppercase; font-weight: 600;">Importe</th>
                            </tr>
                        </thead>
                        <tbody style="padding: 20px;">
                            <!-- Mano de Obra -->
                            <tr>
                                <td style="padding: 15px 20px; border-bottom: 1px solid #e2e8f0; color: #1e293b; font-weight: 500;">
                                    🔧 Mano de Obra
                                    <div style="font-size: 13px; color: #64748b; font-weight: normal; margin-top: 4px;">{cita.servicio.nombre if cita else "Servicio General"}</div>
                                </td>
                                <td style="padding: 15px 20px; border-bottom: 1px solid #e2e8f0; color: #1e293b; text-align: right; font-weight: 500;">Q{monto_mo:.2f}</td>
                            </tr>
                            
                            <!-- Repuestos -->
                            {f'''<tr>
                                <td colspan="2" style="padding: 15px 20px 5px 20px; color: #1e293b; font-weight: 500;">
                                    ⚙️ Repuestos Instalados
                                    <table style="width: 100%; font-size: 14px; margin-top: 10px;">
                                        {filas_repuestos_html}
                                    </table>
                                </td>
                            </tr>''' if filas_repuestos_html else ""}
                        </tbody>
                    </table>
                    
                    <!-- Totales -->
                    <div style="background-color: #f1f5f9; padding: 20px;">
                        <table style="width: 100%; border-collapse: collapse;">
                            <tr>
                                <td style="padding: 5px 0; color: #64748b; font-size: 15px;">Subtotal</td>
                                <td style="padding: 5px 0; text-align: right; color: #1e293b; font-size: 15px;">Q{subtotal:.2f}</td>
                            </tr>
                            {f'''<tr>
                                <td style="padding: 5px 0; color: #ef4444; font-size: 15px;">Descuento</td>
                                <td style="padding: 5px 0; text-align: right; color: #ef4444; font-size: 15px;">-Q{monto_dto:.2f}</td>
                            </tr>''' if monto_dto > 0 else ""}
                            <tr>
                                <td style="padding: 15px 0 5px 0; border-top: 1px solid #cbd5e1; color: #0f172a; font-weight: bold; font-size: 18px; text-transform: uppercase;">Total Pagado</td>
                                <td style="padding: 15px 0 5px 0; border-top: 1px solid #cbd5e1; text-align: right; color: #3b82f6; font-weight: bold; font-size: 20px;">Q{total:.2f}</td>
                            </tr>
                        </table>
                    </div>
                </div>
                
                <!-- Detalles del pago -->
                <div style="font-size: 14px; color: #475569; margin-bottom: 25px; padding: 15px; background-color: #f8fafc; border-radius: 6px; border-left: 4px solid #10b981;">
                    ✅ <strong>Pago liquidado</strong> mediante <strong>{factura.get_metodo_pago_display()}</strong>. Gracias por tu preferencia.
                </div>
            </div>
            
            <!-- Footer -->
            <div style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; color: #64748b; padding: 25px; text-align: center; font-size: 13px;">
                <p style="margin: 0 0 8px 0; font-weight: bold; color: #475569;">Taller Mecánico Profesional</p>
                <p style="margin: 0 0 15px 0;">Este documento es un comprobante electrónico válido de tu compra.</p>
                <p style="margin: 0; font-size: 11px; opacity: 0.7;">Generado el {datetime.datetime.now().strftime('%d/%m/%Y %H:%M:%S')}</p>
            </div>
            
        </div>
    </body>
    </html>
    """

    # Texto Alternativo Resiliente
    mensaje_texto = f"""
🧾 COMPROBANTE DE PAGO
Taller Mecánico Profesional

Factura a: {cliente_nombre}
Vehículo: {vehiculo_desc}
Folio: {factura.numero_factura}
Fecha Emisión: {fecha_emision}

=======================================
DESGLOSE:
---------------------------------------
🔧 Mano de Obra: Q{monto_mo:.2f}

⚙️ Repuestos Instalados:
{filas_repuestos_txt if filas_repuestos_txt else "Ninguno"}

---------------------------------------
Subtotal: Q{subtotal:.2f}
Descuento: -Q{monto_dto:.2f}
=======================================
TOTAL PAGADO: Q{total:.2f}
=======================================

✅ Pago exitoso mediante {factura.get_metodo_pago_display()}

Gracias por tu preferencia.
Este es un comprobante digital generado automáticamente.
""".strip()
    
    try:
        # Enviar el Payload SMTP
        email = EmailMultiAlternatives(
            asunto,
            mensaje_texto,
            settings.EMAIL_HOST_USER,
            [destinatario_email]
        )
        email.attach_alternative(mensaje_html, "text/html")
        email.send()
        
        return True
    except Exception as e:
        print(f"[facturacion/utils.py] Error enviando factura HTML: {e}")
        return False
