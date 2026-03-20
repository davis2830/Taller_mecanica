from django.core.management.base import BaseCommand
import openpyxl
from apps.clientes.models import Cliente
from apps.vehiculos.models import Vehiculo
from apps.servicios.models import OrdenTrabajo

class Command(BaseCommand):
    help = 'Importa datos históricos desde Excel'

    def add_arguments(self, parser):
        parser.add_argument('excel_file', type=str)

    def handle(self, *args, **options):
        wb = openpyxl.load_workbook(options['excel_file'])
        
        # Importar clientes
        ws_clientes = wb['Clientes']
        for row in ws_clientes.iter_rows(min_row=2, values_only=True):
            Cliente.objects.get_or_create(
                dpi=row[5],
                defaults={
                    'nombre': row[0],
                    'apellido': row[1],
                    'telefono': row[2],
                    'email': row[3],
                    'direccion': row[4],
                    'nit': row[6]
                }
            )
        
        # Importar vehículos y servicios...
        self.stdout.write(self.style.SUCCESS('Importación completada'))