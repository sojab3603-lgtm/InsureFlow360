@IsTest
global class MockKYCResponse implements HttpCalloutMock {

    global HttpResponse respond(HttpRequest request) {

        HttpResponse response = new HttpResponse();

        response.setHeader(
            'Content-Type',
            'application/json'
        );

        response.setBody(
            '{"status":"verified"}'
        );

        response.setStatusCode(200);

        return response;
    }
}