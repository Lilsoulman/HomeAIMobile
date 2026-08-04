import 'dto.dart';

abstract class ConnectorRepository {
  Future<List<ConnectorProviderDto>> listProviders();

  Future<List<ConnectorDto>> listConnectors();

  Future<ConnectorDto> beginAuthorization(String providerKey);

  Future<ConnectorDto> retry(String connectorId);

  Future<ConnectorDto> discover(String connectorId);

  Future<ConnectorDto> disconnect(String connectorId);
}
