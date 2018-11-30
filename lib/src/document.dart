import 'dart:async';
import 'collection.dart';
import 'helpers.dart';
import 'response.dart';
import 'room.dart';

class Document extends KuzzleObject {
  Document(
    Collection collection,
    this.id,
    this.content, {
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.active,
    this.version,
  }) : super(collection);

  Document.fromMap(Collection collection, Map<String, dynamic> map)
      : assert(map['_id'] != null),
        assert(map['_source'] != null),
        id = map['_id'],
        version = map['_version'],
        content = map['_source'],
        super(collection) {
    content.remove('_kuzzle_info');
    final Map<String, dynamic> mapMeta = extractMeta(map);
    createdAt = mapMeta['createdAt'] == null
        ? mapMeta['createdAt']
        : DateTime.fromMillisecondsSinceEpoch(mapMeta['createdAt']);
    updatedAt = mapMeta['updatedAt'] == null
        ? mapMeta['updatedAt']
        : DateTime.fromMillisecondsSinceEpoch(mapMeta['updatedAt']);
    deletedAt = mapMeta['deletedAt'] == null
        ? mapMeta['deletedAt']
        : DateTime.fromMillisecondsSinceEpoch(mapMeta['deletedAt']);
    active = mapMeta['active'];
  }

  static Map<String, dynamic> extractMeta(Map<String, dynamic> map) {
    if (map.containsKey('_meta')) {
      return map['_meta'];
    } else if (map.containsKey('_source') &&
        map['_source'].containsKey('_kuzzle_info')) {
      return map['_source']['_kuzzle_info'];
    } else {
      return <String, dynamic>{
        'createdAt': null,
        'updatedAt': null,
        'deletedAt': null,
        'active': null,
      };
    }
  }

  String id;
  int version;
  Map<String, dynamic> content;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime deletedAt;
  bool active;

  static const String controller = 'document';

  @override
  String toString() => toMap().toString();

  Map<String, dynamic> toMap() => <String, dynamic>{
        '_id': id,
        'content': content,
        'version': version,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'deletedAt': deletedAt,
        'active': active,
      };

  Map<String, dynamic> get meta => <String, dynamic>{};

  Future<String> delete({
    Map<String, dynamic> volatile,
    bool queuable = true,
    String refresh = 'false',
  }) async =>
      addNetworkQuery(<String, dynamic>{
        'action': 'delete',
        'refresh': refresh,
        '_id': id,
      }, queuable: queuable)
          .then((RawKuzzleResponse response) => response.result['_id']);

  Future<bool> exists({
    Map<String, dynamic> volatile,
    bool queuable = true,
  }) async =>
      addNetworkQuery(<String, dynamic>{
        'action': 'exists',
        '_id': id,
      }, queuable: queuable)
          .then((RawKuzzleResponse response) => response.result as bool);

  Future<bool> publish({
    Map<String, dynamic> volatile,
    bool queuable = true,
  }) async =>
      collection.publishMessage(content,
          volatile: volatile, queuable: queuable);

  Future<Document> refresh({
    bool queuable = true,
  }) async {
    final Document document =
        await collection.fetchDocument(id, queuable: queuable);
    content = document.content;
    version = document.version;
    createdAt = document.createdAt;
    updatedAt = document.updatedAt;
    deletedAt = document.deletedAt;
    active = document.active;
    return document;
  }

  Future<Document> save({
    Map<String, dynamic> volatile,
    bool queuable = true,
    String refresh,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'volatile': volatile,
      'body': content,
    };
    if (id == null) {
      query['action'] = 'create';
    } else {
      query['action'] = 'createOrReplace';
      query['_id'] = id;
    }
    final Document document = await addNetworkQuery(query, queuable: queuable)
        .then((RawKuzzleResponse response) =>
            Document.fromMap(collection, response.result));
    id = document.id;
    version = document.version;
    return this;
  }

  void setContent(
    Map<String, dynamic> content, {
    bool replace = false,
  }) =>
      content.addAll(content);

  Future<Room> subscribe(
    NotificationCallback notificationCallback, {
    Map<String, dynamic> query = emptyMap,
    final Map<String, dynamic> volatile = emptyMap,
    bool subscribeToSelf,
    RoomScope scope = RoomScope.all,
    RoomState state = RoomState.done,
    RoomUsersScope users = RoomUsersScope.none,
  }) async =>
      collection.subscribe(
        notificationCallback,
        query: query,
        volatile: volatile,
        subscribeToSelf: subscribeToSelf,
        scope: scope,
        state: state,
        users: users,
      );
}
